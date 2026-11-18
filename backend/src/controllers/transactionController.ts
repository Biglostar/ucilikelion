import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generatePushNotification } from "../services/aiService";
import { syncMonthlySummary } from "../services/summaryService";
import { refreshCharacterState } from "../services/characterService";
import { sendPushNotification } from "../services/pushService";
import { evaluateCheckpoint, remainingPctOf } from "../services/goalService";
import { rolloverStaleGoals } from "./dashboardController";

// 목표 기간(해당 월) 밖의 거래는 게이지에 반영하지 않음
function isWithinGoalPeriod(goal: { startDate: Date; endDate: Date }, date: Date) {
  return date >= goal.startDate && date <= goal.endDate;
}

export async function getTransactions(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id") as string;
    if (!userId) {
      return res.status(400).json({ error: "Missing x-user-id header" });
    }

    const { from, to } = req.query;
    const whereClause: any = { userId };

    if (from || to) {
      whereClause.occurredAt = {};
      
      if (from) {
        whereClause.occurredAt.gte = new Date(from as string);
      }
      
      if (to) {
        const toDate = new Date(to as string);
        toDate.setUTCHours(23, 59, 59, 999); 
        whereClause.occurredAt.lte = toDate;
      }
    }

    // console.log("Searching with filter:", JSON.stringify(whereClause, null, 2));

    const transactions = await prisma.transaction.findMany({
      where: whereClause,
      orderBy: {
        occurredAt: "desc",
      },
    });

    return res.json(transactions);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to fetch transactions" });
  }
}

export async function createTransaction(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id") as string;
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    const { title, amountCents, type, category, isFixed, note } = req.body;
    const { occurredAt } = req.body;

    const dateObj = new Date(occurredAt);
    const year = dateObj.getFullYear();
    const month = dateObj.getMonth() + 1;

    // 달이 바뀐 뒤 대시보드를 열기 전에 들어온 지출도 이번 달 목표에 반영되도록 먼저 rollover
    await rolloverStaleGoals(userId);

    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.findUnique({
        where: { id: userId },
        select: { id: true, fcmToken: true, roastLevel: true }
      });
      if (!user) throw new Error("User not found");

      // 2. 지출 생성
      const transaction = await tx.transaction.create({
        data: { userId, title, amountCents, type, category, occurredAt: dateObj, isFixed: isFixed ?? false, note },
      });

      // 3. MonthlySummary 재계산 (순지출 = 지출 − 환급)
      await syncMonthlySummary(userId, year, month, tx);

      if (type === "INCOME") {
        // If this income belongs to a goal category (e.g. friends paying back their share),
        // reduce the goal's spending so the gauge reflects the real net cost.
        const offsetGoal = await tx.goal.findFirst({
          where: { userId, category, status: "ACTIVE" },
          orderBy: { isSelected: "desc" },
        });
        if (offsetGoal && isWithinGoalPeriod(offsetGoal, dateObj)) {
          const newSpent = Math.max(0, offsetGoal.currentSpentCents - amountCents);
          const { lastAlertPct } = evaluateCheckpoint(offsetGoal.lastAlertPct, remainingPctOf(newSpent, offsetGoal.monthlyBudgetCents));
          await tx.goal.update({
            where: { id: offsetGoal.id },
            data: { currentSpentCents: newSpent, lastAlertPct },
          });
        }
        return { transaction, goalAlert: null, user };
      }

      // --- 카테고리: 푸시 알림 체크 ---
      const goal = await tx.goal.findFirst({
        where: { userId, category, status: "ACTIVE" },
        orderBy: { isSelected: "desc" }
      });

      let goalAlert: { checkpoint: number } | null = null;

      if (goal && isWithinGoalPeriod(goal, dateObj)) {
        const newGoalSpent = goal.currentSpentCents + amountCents;
        const { crossedCheckpoint, lastAlertPct } = evaluateCheckpoint(
          goal.lastAlertPct,
          remainingPctOf(newGoalSpent, goal.monthlyBudgetCents)
        );

        // checkpoint를 지났거나, 예산 초과 상태에서 또 지출하면 매번 알림
        if (crossedCheckpoint !== null || newGoalSpent > goal.monthlyBudgetCents) {
          goalAlert = { checkpoint: crossedCheckpoint ?? 0 };
        }

        await tx.goal.update({
          where: { id: goal.id },
          data: { currentSpentCents: newGoalSpent, lastAlertPct }
        });
      }

      return { transaction, goalAlert, user };
    }, { timeout: 20000 });

    // 4. 캐릭터/말풍선 갱신 — AI 호출은 DB 트랜잭션 밖에서 (응답 지연으로 거래 저장이 롤백되지 않도록)
    await refreshCharacterState(userId);

    // 5. 푸시 발송
    if (result.goalAlert && result.user.fcmToken) {
      const message = await generatePushNotification(category, result.goalAlert.checkpoint, result.user.roastLevel);
      sendPushNotification(result.user.fcmToken, "지출!!", message)
        .catch(e => console.error("Push failed:", e));
    } else if (result.goalAlert) {
      console.warn(`[Push] user ${userId}: fcmToken 없음 — 알림 스킵 (checkpoint ${result.goalAlert.checkpoint})`);
    }

    return res.status(201).json(result.transaction);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Transaction creation failed" });
  }
}

export async function updateTransaction(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id") as string;
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    const id = req.params.id as string;
    const { title, amountCents, type, category, occurredAt, isFixed, note } = req.body;

    const updated = await prisma.$transaction(async (tx) => {
      const existing = await tx.transaction.findFirst({ where: { id, userId } });
      if (!existing) throw new Error("Transaction not found");

      const newOccurredAt = occurredAt ? new Date(occurredAt) : existing.occurredAt;
      const newAmountCents = amountCents ?? existing.amountCents;
      const newType = type ?? existing.type;
      const newCategory = category ?? existing.category;

      // Goal: undo the effect of the old transaction, then apply the new one
      const oldGoal = await tx.goal.findFirst({
        where: { userId, category: existing.category, status: "ACTIVE" },
        orderBy: { isSelected: "desc" },
      });
      if (oldGoal && isWithinGoalPeriod(oldGoal, existing.occurredAt)) {
        const revert = existing.type === "EXPENSE"
          ? Math.max(0, oldGoal.currentSpentCents - existing.amountCents)   // undo expense
          : oldGoal.currentSpentCents + existing.amountCents;               // undo income offset
        const { lastAlertPct } = evaluateCheckpoint(oldGoal.lastAlertPct, remainingPctOf(revert, oldGoal.monthlyBudgetCents));
        await tx.goal.update({ where: { id: oldGoal.id }, data: { currentSpentCents: revert, lastAlertPct } });
      }

      const newGoal = await tx.goal.findFirst({
        where: { userId, category: newCategory, status: "ACTIVE" },
        orderBy: { isSelected: "desc" },
      });
      let goalAlert: { category: string; checkpoint: number } | null = null;
      if (newGoal && isWithinGoalPeriod(newGoal, newOccurredAt)) {
        const fresh = await tx.goal.findUnique({ where: { id: newGoal.id } });
        const apply = newType === "EXPENSE"
          ? fresh!.currentSpentCents + newAmountCents                        // add expense
          : Math.max(0, fresh!.currentSpentCents - newAmountCents);          // apply income offset
        const { crossedCheckpoint, lastAlertPct } = evaluateCheckpoint(
          fresh!.lastAlertPct,
          remainingPctOf(apply, fresh!.monthlyBudgetCents)
        );
        // 수정 결과 원래보다 지출이 늘어난 경우에만 알림 (createTransaction과 동일한 기준)
        const spentBefore = oldGoal?.id === newGoal.id ? oldGoal.currentSpentCents : newGoal.currentSpentCents;
        const spentIncreased = apply > spentBefore;
        if (spentIncreased && (crossedCheckpoint !== null || apply > fresh!.monthlyBudgetCents)) {
          goalAlert = { category: newCategory, checkpoint: crossedCheckpoint ?? 0 };
        }
        await tx.goal.update({ where: { id: newGoal.id }, data: { currentSpentCents: apply, lastAlertPct } });
      }

      const transaction = await tx.transaction.update({
        where: { id },
        data: {
          ...(title !== undefined && { title }),
          ...(amountCents !== undefined && { amountCents }),
          ...(type !== undefined && { type }),
          ...(category !== undefined && { category }),
          ...(occurredAt !== undefined && { occurredAt: newOccurredAt }),
          ...(isFixed !== undefined && { isFixed }),
          ...(note !== undefined && { note }),
        },
      });

      // MonthlySummary: 이전 월과 새 월 모두 재계산
      await syncMonthlySummary(userId, existing.occurredAt.getFullYear(), existing.occurredAt.getMonth() + 1, tx);
      if (newOccurredAt.getFullYear() !== existing.occurredAt.getFullYear() || newOccurredAt.getMonth() !== existing.occurredAt.getMonth()) {
        await syncMonthlySummary(userId, newOccurredAt.getFullYear(), newOccurredAt.getMonth() + 1, tx);
      }

      return { transaction, goalAlert };
    }, { timeout: 20000 });

    await refreshCharacterState(userId);

    if (updated.goalAlert) {
      const user = await prisma.user.findUnique({ where: { id: userId }, select: { fcmToken: true, roastLevel: true } });
      if (user?.fcmToken) {
        const message = await generatePushNotification(updated.goalAlert.category, updated.goalAlert.checkpoint, user.roastLevel);
        sendPushNotification(user.fcmToken, "지출!!", message)
          .catch(e => console.error("Push failed:", e));
      } else {
        console.warn(`[Push] user ${userId}: fcmToken 없음 — 알림 스킵 (checkpoint ${updated.goalAlert.checkpoint})`);
      }
    }

    return res.status(200).json(updated.transaction);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to update transaction" });
  }
}

export async function deleteTransaction(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id") as string;
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    const id = req.params.id as string;

    await prisma.$transaction(async (tx) => {
      const existing = await tx.transaction.findUnique({ where: { id } });
      if (!existing) throw Object.assign(new Error("Transaction not found"), { status: 404 });
      if (existing.userId !== userId) throw Object.assign(new Error("Unauthorized"), { status: 403 });

      await tx.transaction.delete({ where: { id } });

      await syncMonthlySummary(userId, existing.occurredAt.getFullYear(), existing.occurredAt.getMonth() + 1, tx);

      // Keep goal gauge accurate: undo expense or reverse income offset
      const goal = await tx.goal.findFirst({
        where: { userId, category: existing.category, status: "ACTIVE" },
        orderBy: { isSelected: "desc" },
      });
      if (goal && isWithinGoalPeriod(goal, existing.occurredAt)) {
        const updated = existing.type === "EXPENSE"
          ? Math.max(0, goal.currentSpentCents - existing.amountCents)
          : goal.currentSpentCents + existing.amountCents;
        const { lastAlertPct } = evaluateCheckpoint(goal.lastAlertPct, remainingPctOf(updated, goal.monthlyBudgetCents));
        await tx.goal.update({
          where: { id: goal.id },
          data: { currentSpentCents: updated, lastAlertPct },
        });
      }
    }, { timeout: 20000 });

    await refreshCharacterState(userId);

    return res.status(200).json({ message: "Deleted successfully" });
  } catch (e: any) {
    if (e.status === 404) return res.status(404).json({ error: "Transaction not found" });
    if (e.status === 403) return res.status(403).json({ error: "Unauthorized" });
    console.error(e);
    return res.status(500).json({ error: "Failed to delete transaction" });
  }
}