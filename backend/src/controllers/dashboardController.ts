import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generateNaggingMessage } from "../services/aiService";


export async function getDashboardData(req: Request, res: Response) {
  try {
    const rawUserId = req.header("x-user-id");
    const userId = typeof rawUserId === 'string' ? rawUserId : undefined;
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;

    // 1. 지난 3개월의 월 정보 계산
    const last3Months = [];
    for (let i = 1; i <= 3; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      last3Months.push({ year: d.getFullYear(), month: d.getMonth() + 1 });
    }

    const [user, goals, currentMonthSummary, historySummaries] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.goal.findMany({
        where: { userId, status: "ACTIVE" },
        orderBy: { isSelected: "desc" }
      }),
      // 이번 달 소비액 <-테이블에서 가져오기
      prisma.monthlySummary.findUnique({
        where: {
          userId_year_month: { userId, year: currentYear, month: currentMonth }
        }
      }),
      // 지난 3개월 데이터 (평균 예산 계산)
      prisma.monthlySummary.findMany({
        where: {
          userId,
          OR: last3Months
        }
      })
    ]);

    if (!user) return res.status(404).json({ error: "User not found" });

    // 이번 달 예산 결정
    const totalThreeMonthSpent = historySummaries.reduce((sum, s) => sum + s.totalSpentCents, 0);
    const totalMonthlyBudget = Math.floor(totalThreeMonthSpent / 3); 

    // 이번 달 지출액
    const totalMonthSpent = currentMonthSummary?.totalSpentCents || 0;
    
    // 나머지
    const totalRemainingAmount = Math.max(0, totalMonthlyBudget - totalMonthSpent);
    const totalRemainingPct = totalMonthlyBudget > 0 
      ? Math.min(100, Math.max(0, (totalRemainingAmount / totalMonthlyBudget) * 100))
      : 0;

    // 개별 목표 진행률 계산
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

    // 캐릭터 상태
    let characterStatus: "RICH" | "STABLE" | "SURVIVING" | "DESPERATE" | "BROKE" = "RICH";
    if (totalRemainingPct > 75) characterStatus = "RICH";
    else if (totalRemainingPct > 50) characterStatus = "STABLE";
    else if (totalRemainingPct > 25) characterStatus = "SURVIVING";
    else if (totalRemainingPct > 0) characterStatus = "DESPERATE";
    else characterStatus = "BROKE";

    // ai 메시지 생성
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