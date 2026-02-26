import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generateNaggingMessage, generatePushNotification } from "../services/aiService";
import { updateMonthlySummary } from "../services/summaryService";

function getNaggingCheckpoint(lastAlertPct: number, remainingPct: number) {
  const checkpoints = [100, 75, 50, 25, 10, 0];
  // 사용자가 지출을 해서 remainingPct가 떨어질 때, 어떤 체크포인트를 돌파 했는지 체크
  const crossed = checkpoints
    .filter((cp) => remainingPct <= cp && lastAlertPct > cp)
    .sort((a, b) => a - b)[0]; // 가장 먼저 만난거 선택
  return crossed !== undefined ? crossed : null;
}

export async function getTransactions(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id") as string;
    if (!userId) {
      return res.status(400).json({ error: "Missing x-user-id header" });
    }

    const { from, to } = req.query;

    // 1. Start with the base filter (just the user ID)
    const whereClause: any = { userId };

    // 2. Safely add dates ONLY if they exist in the URL
    if (from || to) {
      whereClause.occurredAt = {};
      
      if (from) {
        whereClause.occurredAt.gte = new Date(from as string);
      }
      
      if (to) {
        const toDate = new Date(to as string);
        // Push the cutoff to the very last millisecond of the day!
        toDate.setUTCHours(23, 59, 59, 999); 
        whereClause.occurredAt.lte = toDate;
      }
    }

    // DEBUG: This will print in your terminal so we know exactly what is happening
    console.log("Searching with filter:", JSON.stringify(whereClause, null, 2));

    // 3. Pass the safely built object to Prisma
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

    const { title, amountCents, type, category, occurredAt, isFixed, note } = req.body;

    if (!title || !category || !type || !occurredAt) return res.status(400).json({ error: "Missing required fields" });
    const amount = Number(amountCents);
    if (isNaN(amount) || amount <= 0) return res.status(400).json({ error: "amountCents must be > 0" });

    const dateObj = new Date(occurredAt);
    const year = dateObj.getFullYear();
    const month = dateObj.getMonth() + 1;

    const result = await prisma.$transaction(async (tx) => {
      //transaction 생성
      const transaction = await tx.transaction.create({
        data: { userId, title, amountCents: amount, type, category, occurredAt: dateObj, isFixed: isFixed ?? false, note },
      });

      // monthlySummary 업데이트 
      if (type === "EXPENSE") {
        await tx.monthlySummary.upsert({
          where: {
            userId_year_month: { userId, year, month }
          },
          update: {
            totalSpentCents: { increment: amount }
          },
          create: {
            userId,
            year,
            month,
            totalSpentCents: amount
          }
        });
      }

      if (type === "INCOME") {
        return { transaction, goal: null, alert: { shouldNotify: false } };
      }

      // user & active goal 찾기
      const user = await tx.user.findUnique({ where: { id: userId } });
      const goal = await tx.goal.findFirst({
        where: { userId, category, status: "ACTIVE" },
        orderBy: [{ isSelected: "desc" }, { createdAt: "desc" }]
      });

      if (!goal || !user) return { transaction, alert: { shouldNotify: false } };

      // 예산 계산
      const newSpent = goal.currentSpentCents + transaction.amountCents;
      const remainingPct = ((goal.monthlyBudgetCents - newSpent) / goal.monthlyBudgetCents) * 100;

      //알림 트리거 확인 및 캐릭터 상태 결정
      const currentCheckpoint = getNaggingCheckpoint(goal.lastAlertPct, remainingPct);
      const isOverBudget = newSpent > goal.monthlyBudgetCents;
      const shouldNotify = isOverBudget || currentCheckpoint !== null;

      let characterStatus: "RICH" | "STABLE" | "SURVIVING" | "DESPERATE" | "BROKE" = "RICH";
      if (remainingPct > 75) characterStatus = "RICH";
      else if (remainingPct > 50) characterStatus = "STABLE";
      else if (remainingPct > 25) characterStatus = "SURVIVING";
      else if (remainingPct > 0) characterStatus = "DESPERATE";
      else characterStatus = "BROKE";

      // 메시지 생성
      let naggingMessage = "";
      if (shouldNotify) {
        const displayPct = isOverBudget ? 0 : (currentCheckpoint ?? Math.floor(remainingPct));
        naggingMessage = await generatePushNotification(
          goal.category,
          displayPct,
          user.roastLevel
        );
      }

      // goal 업데이트
      const updatedGoal = await tx.goal.update({
        where: { id: goal.id },
        data: {
          currentSpentCents: newSpent,
          lastAlertPct: isOverBudget ? -1 : (currentCheckpoint !== null ? currentCheckpoint : goal.lastAlertPct)
        }
      });

      return {
        transaction,
        goal: updatedGoal,
        alert: { 
          shouldNotify, 
          message: naggingMessage,
          characterStatus
        }
      };
    }, {timeout: 20000});

    return res.status(201).json(result);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to create transaction" });
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