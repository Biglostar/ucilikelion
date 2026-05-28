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

// 최근 3개월(이번 달 제외) 평균 지출로 예산 자동 계산
export const recalculateBudgets = async (userId: string) => {
  const now = new Date();
  const last3Months = [1, 2, 3].map(i => {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    return { year: d.getFullYear(), month: d.getMonth() + 1 };
  });

  // 최근 3개월 거래내역
  const oldest = new Date(now.getFullYear(), now.getMonth() - 3, 1);
  const startOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const txns = await prisma.transaction.findMany({
    where: {
      userId,
      type: 'EXPENSE',
      occurredAt: { gte: oldest, lt: startOfThisMonth }
    }
  });

  // 월별 총 지출 계산
  const monthTotals: Record<string, number> = {};
  for (const tx of txns) {
    const d = new Date(tx.occurredAt);
    const key = `${d.getFullYear()}-${d.getMonth() + 1}`;
    monthTotals[key] = (monthTotals[key] || 0) + tx.amountCents;
  }

  const monthValues = last3Months
    .map(m => monthTotals[`${m.year}-${m.month}`] || 0)
    .filter(v => v > 0);

  if (monthValues.length > 0) {
    const avgTotal = Math.floor(monthValues.reduce((a, b) => a + b, 0) / monthValues.length);
    await prisma.user.update({
      where: { id: userId },
      data: { totalMonthlyBudgetCents: avgTotal }
    });
  }

  // 카테고리별 예산도 AUTO_AVG_3M 목표에 업데이트
  const autoGoals = await prisma.goal.findMany({
    where: { userId, status: 'ACTIVE', budgetSource: 'AUTO_AVG_3M' }
  });

  for (const goal of autoGoals) {
    const catTxns = txns.filter(tx => tx.category === goal.category);
    const catMonthTotals: Record<string, number> = {};
    for (const tx of catTxns) {
      const d = new Date(tx.occurredAt);
      const key = `${d.getFullYear()}-${d.getMonth() + 1}`;
      catMonthTotals[key] = (catMonthTotals[key] || 0) + tx.amountCents;
    }
    const catValues = last3Months
      .map(m => catMonthTotals[`${m.year}-${m.month}`] || 0)
      .filter(v => v > 0);

    if (catValues.length > 0) {
      const avgCat = Math.floor(catValues.reduce((a, b) => a + b, 0) / catValues.length);
      await prisma.goal.update({
        where: { id: goal.id },
        data: { monthlyBudgetCents: avgCat, baselineAvg3mCents: avgCat }
      });
    }
  }
};

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
