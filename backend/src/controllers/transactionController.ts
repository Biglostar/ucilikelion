import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generateNaggingMessage, generatePushNotification } from "../services/aiService";
import { updateMonthlySummary } from "../services/summaryService";
import { sendPushNotification } from "../services/pushService";
/**
 * 전체 잔여 예산 비율에 따라 캐릭터의 경제적 상태를 결정합니다.
 * @param totalRemainingPct 전체 예산 대비 남은 금액 비율 (0 ~ 100)
 * @returns "RICH" | "STABLE" | "SURVIVING" | "DESPERATE" | "BROKE"
 */
export function determineStatus(totalRemainingPct: number): "RICH" | "STABLE" | "SURVIVING" | "DESPERATE" | "BROKE" {
  if (totalRemainingPct > 75) {
    return "RICH";
  } else if (totalRemainingPct > 50) {
    return "STABLE";
  } else if (totalRemainingPct > 25) {
    return "SURVIVING";
  } else if (totalRemainingPct > 0) {
    return "DESPERATE";
  } else {
    return "BROKE";
  }
}

function getNaggingCheckpoint(lastAlertPct: number, remainingPct: number) {
  const checkpoints = [100, 75, 50, 25, 10, 0];
  const crossed = checkpoints
    .filter((cp) => remainingPct <= cp && lastAlertPct > cp)
    .sort((a, b) => a - b)[0];
  return crossed !== undefined ? crossed : null;
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

    const result = await prisma.$transaction(async (tx) => {
    const user = await tx.user.findUnique({ 
      where: { id: userId },
      select: { id: true, fcmToken: true, roastLevel: true, characterStatus: true, characterMessage: true, lastTotalAlertPct: true, totalMonthlyBudgetCents: true }
    });
    if (!user) throw new Error("User not found");

      // 2. 지출 생성
    const transaction = await tx.transaction.create({
        data: { userId, title, amountCents, type, category, occurredAt: dateObj, isFixed: isFixed ?? false, note },
    });

    if (type === "INCOME") return { transaction, alert: { shouldNotify: false } };

      // 3. MonthlySummary 업데이트 (전체 지출 합산)
    const summary = await tx.monthlySummary.upsert({
        where: { userId_year_month: { userId, year, month } },
        update: { totalSpentCents: { increment: amountCents } },
        create: { userId, year, month, totalSpentCents: amountCents }
      });

      // --- 카테고리: 푸시 알림 체크 ---
    const goal = await tx.goal.findFirst({
    where: { userId, category, status: "ACTIVE" },
    orderBy: { isSelected: "desc" }
  });

  let naggingMessage = "";
  let shouldNotifyPush = false;

if (goal) {
  const newGoalSpent = goal.currentSpentCents + amountCents;
  const goalRemainingPct = ((goal.monthlyBudgetCents - newGoalSpent) / goal.monthlyBudgetCents) * 100;
  
  // 1. 체크포인트 통과 여부 확인
  const goalCheckpoint = getNaggingCheckpoint(goal.lastAlertPct, goalRemainingPct);

  if (goalCheckpoint !== null || newGoalSpent > goal.monthlyBudgetCents) {
    shouldNotifyPush = true;
    // AI 서비스 호출하여 메시지 생성
    naggingMessage = await generatePushNotification(category, goalCheckpoint ?? 0, user.roastLevel);
  }

  // 2. 알림 여부와 상관없이 지출액은 무조건 업데이트
  await tx.goal.update({
    where: { id: goal.id },
    data: { 
      currentSpentCents: newGoalSpent, 
      // 알림이 발생했을 때만 체크포인트 기록, 아니면 기존 값 유지
      lastAlertPct: goalCheckpoint !== null ? goalCheckpoint : goal.lastAlertPct
    }
  });
}

      // --- 전체 월: 캐릭터 상태 업데이트 ---
    const totalBudget = user.totalMonthlyBudgetCents;
    const totalSpent = summary.totalSpentCents;
    const totalRemainingPct = ((totalBudget - totalSpent) / totalBudget) * 100;
    console.log("Total Spent:", totalSpent, "Remaining %:", totalRemainingPct);
const totalCheckpoint = getNaggingCheckpoint(user.lastTotalAlertPct!, totalRemainingPct);      
    const newStatus = determineStatus(totalRemainingPct);
  console.log("New Calculated Status:", newStatus);
    if (newStatus !== user.characterStatus || totalCheckpoint !== null) {
        const characterMsg = await generateNaggingMessage("monthly_progress", totalCheckpoint ?? Math.floor(totalRemainingPct), user.roastLevel);
        
        await tx.user.update({
          where: { id: userId },
          data: {
            characterStatus: newStatus,
            characterMessage: characterMsg,
            lastTotalAlertPct: totalCheckpoint !== null ? totalCheckpoint : user.lastTotalAlertPct                                            
          }
        });
      }



      return { 
        transaction, 
        alert: { 
          shouldNotify: shouldNotifyPush, 
          message: naggingMessage, 
          characterStatus: newStatus 
        },
        fcmToken: user.fcmToken // 알림 발송용
      };
    }, { timeout: 20000 });

    // 4. 푸시 발송
    if (result.alert.shouldNotify && result.fcmToken) {
      sendPushNotification(result.fcmToken, "지출!!", result.alert.message)
        .catch(e => console.error("Push failed:", e));
    }

    return res.status(201).json(result);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Transaction creation failed" });
  }
}

export async function deleteTransaction(req: Request, res: Response) {
  try {
    const rawUserId = req.header("x-user-id");
    const userId = typeof rawUserId === 'string' ? rawUserId : undefined;

    const { id } = req.params;

    if (!userId || typeof id !== 'string') {
      return res.status(400).json({ error: "Missing required information or invalid ID" });
    }
    
    // Prisma 삭제
    const transaction = await prisma.transaction.delete({ 
      where: { id } 
    });

    // 삭제된 금액만큼 테이블에서 차감
    if (transaction.type === "EXPENSE") {
      await updateMonthlySummary(
        transaction.userId, 
        transaction.occurredAt, 
        -transaction.amountCents
      );
    }

    return res.status(200).json({ message: "Deleted successfully", transaction });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to delete transaction" });
  }
}