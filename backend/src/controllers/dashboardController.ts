import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generateNaggingMessage } from "../services/aiService";

export async function getDashboardData(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    // 1. 이번 달 시작일 & 종료일 계산
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // 2. 지난 3개월 범위 계산 (예: 오늘이 2월이면, 11월 1일 ~ 1월 31일)
    const threeMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 3, 1);

    const [user, goals, totalSpentAggregation, threeMonthStats] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.goal.findMany({
        where: { userId, status: "ACTIVE" },
        orderBy: { isSelected: "desc" }
      }),
      // 이번 달 지출
      prisma.transaction.aggregate({
        where: { userId, type: "EXPENSE", occurredAt: { gte: startOfMonth } },
        _sum: { amountCents: true }
      }),
      // 2. 지난 3개월 총 지출 집계
      prisma.transaction.aggregate({
        where: {
          userId,
          type: "EXPENSE",
          occurredAt: { gte: threeMonthsAgo, lt: startOfMonth }
        },
        _sum: { amountCents: true }
      })
    ]);

    if (!user) return res.status(404).json({ error: "User not found" });

    // 3. 이번 달 예산 결정: 지난 3개월 총 지출 / 3
    const totalThreeMonthSpent = threeMonthStats._sum.amountCents || 0;
    const totalMonthlyBudget = Math.floor(totalThreeMonthSpent / 3); 

    const totalMonthSpent = totalSpentAggregation._sum.amountCents || 0;
    
    // 나머지 계산 로직 (남은 퍼센트 등)
    const totalRemainingAmount = Math.max(0, totalMonthlyBudget - totalMonthSpent);
    // 예산이 0일 경우를 대비한 방어 코드
    const totalRemainingPct = totalMonthlyBudget > 0 
      ? Math.min(100, Math.max(0, (totalRemainingAmount / totalMonthlyBudget) * 100))
      : 0;

    // 목표별 남은 예산과 퍼센트 계산
    const activeGoals = goals.map(goal => {
      const remainingAmount = Math.max(0, goal.monthlyBudgetCents - goal.currentSpentCents);
      const rawPct = (remainingAmount / goal.monthlyBudgetCents) * 100;
      return {
        id: goal.id,
        title: goal.title,
        category: goal.category,
        budget: goal.monthlyBudgetCents,
        spent: goal.currentSpentCents,
        remainingAmount,
        remainingPct: Math.round(Math.min(100, Math.max(0, rawPct))),
        isOverBudget: goal.currentSpentCents > goal.monthlyBudgetCents
      };
    });

    // 4. 캐릭터 상태 결정 (추후 상태 추가해서 수정)
    let characterStatus: "RICH" | "STABLE" | "SURVIVING" | "DESPERATE" | "BROKE" = "RICH";

    if (totalRemainingPct > 75) characterStatus = "RICH";
    else if (totalRemainingPct > 50) characterStatus = "STABLE";
    else if (totalRemainingPct > 25) characterStatus = "SURVIVING";
    else if (totalRemainingPct > 0) characterStatus = "DESPERATE";
    else characterStatus = "BROKE";

    // 5. AI 말풍선 생성
    const bubbleText = await generateNaggingMessage(
      "monthly budget",
      Math.max(0, Math.floor(totalRemainingPct)),
      user.roastLevel
    );

    return res.json({
      summary: {
        totalMonthSpentCents: totalMonthSpent,
        totalMonthlyBudgetCents: totalMonthlyBudget,
        nickname: user.nickname
      },
      activeGoals,
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