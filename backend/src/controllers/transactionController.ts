import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generateNaggingMessage, generatePushNotification } from "../services/aiService";

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
    const userId = req.header("x-user-id");
    if (!userId) {
      return res.status(400).json({ error: "Missing x-user-id header" });
    }

    const { from, to } = req.query;

    const transactions = await prisma.transaction.findMany({
      where: {
        userId,
        ...(from && to
          ? {
              occurredAt: {
                gte: new Date(from as string),
                lte: new Date(to as string),
              },
            }
          : {}),
      },
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
    const userId = req.header("x-user-id");
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    const { title, amountCents, type, category, occurredAt, isFixed, note } = req.body;

    if (!title || !category || !type || !occurredAt) return res.status(400).json({ error: "Missing required fields" });
    const amount = Number(amountCents);
    if (isNaN(amount) || amount <= 0) return res.status(400).json({ error: "amountCents must be > 0" });

    const result = await prisma.$transaction(async (tx) => {
      // 1. Transaction 생성
      const transaction = await tx.transaction.create({
        data: { userId, title,amountCents: Number(amountCents), type, category, occurredAt: new Date(occurredAt), isFixed: isFixed ?? false, note },
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
      const newSpent = goal.currentSpentCents + transaction.amountCents;
      const remainingPct = ((goal.monthlyBudgetCents - newSpent) / goal.monthlyBudgetCents) * 100;

      // 4. 알림 트리거 확인
      const currentCheckpoint = getNaggingCheckpoint(goal.lastAlertPct, remainingPct);
      const isOverBudget = newSpent > goal.monthlyBudgetCents;
      const shouldNotify = isOverBudget || currentCheckpoint !== null;

      // 5. 캐릭터 상태 확인 (나중에 수정 필요))
      let characterStatus: "RICH" | "STABLE" | "SURVIVING" | "DESPERATE" | "BROKE" = "RICH";
        if (remainingPct > 75) characterStatus = "RICH";
        else if (remainingPct > 50) characterStatus = "STABLE";
        else if (remainingPct > 25) characterStatus = "SURVIVING";
        else if (remainingPct > 0) characterStatus = "DESPERATE";
        else characterStatus = "BROKE";

      // 6. AI 메시지 생성
      let naggingMessage = "";
      if (shouldNotify) {
        // 푸쉬 알림용 퍼센트는 체크포인트 값 혹은 0 초과할때 사용
        const displayPct = isOverBudget ? 0 : (currentCheckpoint ?? Math.floor(remainingPct));
        naggingMessage = await generatePushNotification(
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