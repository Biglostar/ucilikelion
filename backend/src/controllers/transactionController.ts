import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generateNaggingMessage } from "../services/aiService";


export async function getTransactions(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
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


// 예산 초과시 (remainingPct < 0) null을 반환. 컨트롤러에서 처리
function getNaggingCheckpoint(lastAlertPct: number, remainingPct: number) {
  if (remainingPct < 0) return null;

  const checkpoints = [75, 50, 25, 10, 0];
  const crossed = checkpoints
    .filter((cp) => cp >= remainingPct && cp < lastAlertPct)
    .sort((a, b) => b - a)[0]; 
  return crossed !== undefined ? crossed : null;
}

export async function createTransaction(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    const { title, amountCents, type, category, occurredAt, isFixed, note } = req.body;

    if (!title || !category || !type || !occurredAt) return res.status(400).json({ error: "Missing required fields" });
    const amount = Number(amountCents);
    if (isNaN(amount) || amount <= 0) return res.status(400).json({ error: "amountCents must be > 0" });

    const result = await prisma.$transaction(async (tx) => {
      // 1. Transaction 생성
      const transaction = await tx.transaction.create({
        data: { userId, title, amountCents: amount, type, category, occurredAt: new Date(occurredAt), isFixed: isFixed ?? false, note },
      });

      if (type === "INCOME") {
        return { transaction, goal: null, alert: { shouldNotify: false } };
      }

      // 2. User & ACTIVE Goal 찾기
      const user = await tx.user.findUnique({ where: { id: userId } });
      const goal = await tx.goal.findFirst({
        where: { userId, category, status: "ACTIVE" },
        orderBy: [{ isSelected: "desc" }, { createdAt: "desc" }]
      });

      if (!goal || !user) return { transaction, alert: { shouldNotify: false } };

      // 3. 예산 계산
      const newSpent = goal.currentSpentCents + amount;
      const remainingPct = ((goal.monthlyBudgetCents - newSpent) / goal.monthlyBudgetCents) * 100;

      // 4. 알림 트리거 확인
      let shouldNotify = false;
      let currentCheckpoint = getNaggingCheckpoint(goal.lastAlertPct, remainingPct);
      let isOverBudget = newSpent > goal.monthlyBudgetCents;

      // 5. 캐릭터 상태 확인 (나중에 수정 필요))
      let characterStatus: "RICH" | "NORMAL" | "POOR" = "NORMAL";
      if (remainingPct > 50) {
        characterStatus = "RICH";
      } else if (remainingPct <= 10) {
        characterStatus = "POOR";
      }

      // 예산 초과면 무조건 알림, 새로운 체크포인트 진입 시 알림
      if (isOverBudget || currentCheckpoint !== null) {
        shouldNotify = true;
      }

      // 6. AI 메시지 생성
      let naggingMessage = "";
      if (shouldNotify) {
        // 예산 초과 시에는 0% 지점으로 간주하여 메시지 생성하도록
        const displayPct = isOverBudget ? 0 : (currentCheckpoint ?? 0);
        naggingMessage = await generateNaggingMessage(
          goal.category,
          displayPct,
          user.roastLevel
        );
      }

      // 7. Goal 업데이트
      // 예산 초과 시; lastAlertPct= -1로 해서 다음 지출 때도 계속 알림하도록
      const updatedGoal = await tx.goal.update({
        where: { id: goal.id },
        data: {
          currentSpentCents: newSpent,
          lastAlertPct: isOverBudget ? -1 : (shouldNotify ? (currentCheckpoint ?? goal.lastAlertPct) : goal.lastAlertPct)
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
    });

    return res.status(201).json(result);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to create transaction" });
  }
}