import { Request, Response } from "express";
import { prisma } from "../prisma";
import { generateNaggingMessage } from "../services/aiService";
import { TransactionType } from '@prisma/client';

export async function getDashboardData(req: Request, res: Response) {
  try {
    const rawUserId = req.header("x-user-id");
    const userId = typeof rawUserId === 'string' ? rawUserId : undefined;
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;



    // 1. 지난 3개월의 월 정보 계산
    const [user, goals, currentMonthSummary] = await Promise.all([
      prisma.user.findUnique({ 
        where: { id: userId },
        select: { 
          nickname: true, 
          totalMonthlyBudgetCents: true, 
          characterStatus: true, 
          characterMessage: true 
        }
      }),
      prisma.goal.findMany({
        where: { userId, status: "ACTIVE" },
        orderBy: { isSelected: "desc" }
      }),
      prisma.monthlySummary.findUnique({
        where: {
          userId_year_month: { userId, year: currentYear, month: currentMonth }
        }
      })
    ]);

    if (!user) return res.status(404).json({ error: "User not found" });

    // 이번 달 예산 결정
    const totalMonthlyBudget = user.totalMonthlyBudgetCents;

    // 이번 달 지출액
    const totalMonthSpent = currentMonthSummary?.totalSpentCents || 0;
  
    console.log(`[Dashboard Debug] User: ${userId}, Year: ${currentYear}, Month: ${currentMonth}`);
  console.log(`[Dashboard Debug] Found Summary Spent: ${currentMonthSummary?.totalSpentCents}`);
  console.log(`[Dashboard Debug] Found Goals Count: ${goals.length}`);
    // 3. 개별 목표 진행률 계산
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

    return res.json({
      summary: {
        totalMonthSpentCents: totalMonthSpent,
        totalMonthlyBudgetCents: totalMonthlyBudget,
        nickname: user.nickname
      },
      activeGoals,
      character: {
        status: user.characterStatus, 
        bubbleText: user.characterMessage 
      }
    });

  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to fetch dashboard data" });
  }
}

// --- REUSABLE HELPER FUNCTION ---
// This handles the math and database updates, without needing req/res!
export const updateUserBudgets = async (userId: string) => {
  const activeGoals = await prisma.goal.findMany({
    where: { userId: userId, status: 'ACTIVE' }
  });

  let updatedCount = 0;

  for (const goal of activeGoals) {
    const spending = await prisma.transaction.aggregate({
      _sum: { amountCents: true },
      where: {
        userId: userId,
        category: goal.category, 
        type: TransactionType.EXPENSE,
        occurredAt: { gte: goal.startDate, lte: goal.endDate }
      }
    });

    const totalSpent = spending._sum.amountCents || 0;

    await prisma.goal.update({
      where: { id: goal.id },
      data: { currentSpentCents: totalSpent }
    });

    updatedCount++;
  }
  
  return updatedCount; // Just return the number of updated goals
};
