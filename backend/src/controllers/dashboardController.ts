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

    // 2. 유저 정보 & active goals, 이번 달 총 지출액 load
    const [user, goals, totalSpentAggregation] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.goal.findMany({
        where: { userId, status: "ACTIVE" },
        orderBy: { isSelected: "desc" } // 선택된 것이 가장 앞에 오도록 정렬
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

    if (!user || goals.length === 0) {
      return res.json({ 
        summary: { nickname: user?.nickname || "User", totalMonthSpentCents: 0 },
        message: "목표를 먼저 설정해주세요!", 
        activeGoals: [],
        character: { status: "RICH", bubbleText: "목표를 설정하고 관리를 시작해볼까?" }
      });
    }

    const totalMonthSpent = totalSpentAggregation._sum.amountCents || 0;
    
    // 월간 예산 합계 계산
    const totalMonthlyBudget = goals.reduce((acc, g) => acc + g.monthlyBudgetCents, 0);
    
    // 월간 예산 남은 퍼센트 계산
    const totalRemainingAmount = Math.max(0, totalMonthlyBudget - totalMonthSpent);
    const totalRemainingPct = Math.min(100, Math.max(0, (totalRemainingAmount / totalMonthlyBudget) * 100));

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

    // 3. 캐릭터 상태 결정 (추후 상태 추가해서 수정)
    let characterStatus: "RICH" | "STABLE" | "SURVIVING" | "DESPERATE" | "BROKE" = "RICH";

    if (totalRemainingPct > 75) characterStatus = "RICH";
    else if (totalRemainingPct > 50) characterStatus = "STABLE";
    else if (totalRemainingPct > 25) characterStatus = "SURVIVING";
    else if (totalRemainingPct > 0) characterStatus = "DESPERATE";
    else characterStatus = "BROKE";

    // 4. AI 말풍선 생성
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