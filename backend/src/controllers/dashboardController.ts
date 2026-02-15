import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generateNaggingMessage } from "../services/aiService";

export async function getDashboardData(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    // 1. 이번 달의 시작일과 종료일 계산
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // 2. 유저 정보 & active goals, 이번 달 총 지출액 load
    const [user, goal, totalSpentAggregation] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.goal.findFirst({
        where: { userId, status: "ACTIVE" },
        orderBy: { isSelected: "desc" }
      }),
      prisma.transaction.aggregate({
        where: {
          userId,
          type: "EXPENSE",
          occurredAt: { gte: startOfMonth }
        },
        _sum: { amountCents: true }
      })
    ]);

    if (!user || !goal) {
      return res.json({ message: "목표를 먼저 설정해주세요!", characterStatus: "NORMAL" });
    }

    const totalMonthSpent = totalSpentAggregation._sum.amountCents || 0;
    const remainingPct = ((goal.monthlyBudgetCents - goal.currentSpentCents) / goal.monthlyBudgetCents) * 100;

    // 3. 캐릭터 상태 결정 (추후 상태 추가해서 수정)
    let characterStatus: "RICH" | "NORMAL" | "POOR" = "NORMAL";
    if (remainingPct > 50) characterStatus = "RICH";
    else if (remainingPct <= 10) characterStatus = "POOR";

    // 4. AI 말풍선 생성
    const bubbleText = await generateNaggingMessage(
      goal.category,
      Math.max(0, Math.floor(remainingPct)),
      user.roastLevel
    );

    // 5. 응답 데이터 구성
    return res.json({
      user: { nickname: user.nickname },
      totalMonthSpent, 
      goal: {
        category: goal.category,
        budget: goal.monthlyBudgetCents,
        spent: goal.currentSpentCents,
        remainingPct
      },
      character: {
        status: characterStatus,
        bubbleText
      }
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to fetch dashboard data" });
  }
}