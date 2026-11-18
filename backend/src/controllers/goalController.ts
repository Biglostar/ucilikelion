import { Request, Response } from 'express';
import { prisma } from "../prisma";
import { generateAiBudgetAnalysis } from '../services/aiService';
import { updateUserBudgets, rolloverStaleGoals, currentMonthRange, calcGoalSpentCents } from './dashboardController';
import { evaluateCheckpoint, remainingPctOf } from '../services/goalService';
import { TransactionType } from '@prisma/client';
// import { generateAiBudgetAnalysis } from '../services/aiService';
// import { TransactionType } from '@prisma/client';

export async function getGoals(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    if (!userId) {
      return res.status(400).json({ error: "Missing x-user-id header" });
    }

    // 달이 바뀌었으면 목표 기간/게이지를 이번 달 기준으로 재계산
    await rolloverStaleGoals(userId);

    const goals = await prisma.goal.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
    });

    const withGauge = goals.map((g: any) => {
      const budget = g.monthlyBudgetCents;

      if (!budget || budget <= 0) {
        return {
          ...g,
          spentPct: 0,
          remainingPct: 0,
          overBudget: false,
        };
      }

      const spentPctRaw = Math.floor((g.currentSpentCents / budget) * 100);
      const spentPct = Math.max(0, spentPctRaw);

      const remainingPct = Math.max(0, 100 - spentPct);
      const overBudget = g.currentSpentCents > budget;

    return {
      ...g,
      spentPct: Math.min(spentPct, 999),
      remainingPct,
      overBudget,
    };
  });

  return res.json(withGauge);

  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to fetch goals" });
  }
}

export async function createGoal(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id") as string;
    let { title, category, monthlyBudgetCents, icon, memo, budgetSource, status } = req.body;
    budgetSource = budgetSource || "USER_SET";

    if (budgetSource === "AUTO_AVG_3M") {
      const now = new Date();
      const oldest = new Date(now.getFullYear(), now.getMonth() - 3, 1);
      const startOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

      const catTxns = await prisma.transaction.findMany({
        where: {
          userId,
          category,
          type: 'EXPENSE',
          occurredAt: { gte: oldest, lt: startOfThisMonth }
        }
      });

      // 월별 지출 합산 후 평균
      const monthTotals: Record<string, number> = {};
      for (const tx of catTxns) {
        const d = new Date(tx.occurredAt);
        const key = `${d.getFullYear()}-${d.getMonth() + 1}`;
        monthTotals[key] = (monthTotals[key] || 0) + tx.amountCents;
      }
      const values = Object.values(monthTotals).filter(v => v > 0);
      if (values.length > 0) {
        monthlyBudgetCents = Math.floor(values.reduce((a, b) => a + b, 0) / values.length);
      } else {
        // 최근 3개월 지출이 없으면 프론트에서 전달한 값 사용, 없으면 0 (이후 사용자가 직접 설정)
        monthlyBudgetCents = Number(monthlyBudgetCents) || 0;
        // 사용자가 정한 예산은 Plaid 동기화 때 recalculateBudgets가 덮어쓰지 않도록 USER_SET으로 저장
        if (monthlyBudgetCents > 0) budgetSource = "USER_SET";
      }
    }

    const { start: startOfMonth, end: endOfMonth } = currentMonthRange();

    const goal = await prisma.goal.create({
      data: {
        userId,
        title,
        category,
        monthlyBudgetCents: Number(monthlyBudgetCents),
        baselineAvg3mCents: budgetSource === "AUTO_AVG_3M" ? Number(monthlyBudgetCents) : null,
        icon: icon || "💰",
        memo: memo?.trim() || `${title} 목표 추가됨`,
        budgetSource,
        status: status || "ACTIVE", 
        startDate: startOfMonth,
        endDate: endOfMonth,
      }
    });

    // 목표 생성 후 이번 달 해당 카테고리 지출 즉시 계산 (n빵 등 수입은 차감)
    const currentSpent = await calcGoalSpentCents(userId, category, startOfMonth, endOfMonth);
    if (currentSpent > 0) {
      await prisma.goal.update({
        where: { id: goal.id },
        data: { currentSpentCents: currentSpent }
      });
    }

    const updatedGoal = await prisma.goal.findUnique({ where: { id: goal.id } });
    return res.status(201).json(updatedGoal);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Goal creation failed" });
  }
}

export async function modifyGoal(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    const goalId = req.params.id as string; // Grab the goal ID from the URL

    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    // 1. Find the goal and verify the user actually owns it
    const existingGoal = await prisma.goal.findUnique({ where: { id: goalId } });
    if (!existingGoal) return res.status(404).json({ error: "Goal not found" });
    if (existingGoal.userId !== userId) return res.status(403).json({ error: "Unauthorized to modify this goal" });

    // 2. Extract whatever fields the frontend sent in the body
    const { title, category, monthlyBudgetCents, icon, memo, budgetSource, status } = req.body;

    // 예산은 아직 0원(최근 3개월 지출 없음)인 목표에만 직접 설정 가능
    if (monthlyBudgetCents !== undefined && monthlyBudgetCents !== null) {
      const budget = Number(monthlyBudgetCents);
      if (!Number.isInteger(budget) || budget <= 0) {
        return res.status(400).json({ error: "monthlyBudgetCents must be a positive integer" });
      }
      if (existingGoal.monthlyBudgetCents > 0) {
        return res.status(409).json({ error: "Budget can only be set when it is $0" });
      }
    }

    // 3. Update only the fields that were provided
    const updatedGoal = await prisma.goal.update({
      where: { id: goalId },
      data: {
        currentSpentCents: newSpent,
        lastAlertPct,
        ...(title && { title }),
        ...(category && { category }),
        ...(monthlyBudgetCents && { monthlyBudgetCents: Number(monthlyBudgetCents) }),
        ...(icon && { icon }),
        ...(memo !== undefined && { memo }),
        ...(budgetSource && { budgetSource }),
        // 예산을 직접 설정하면 USER_SET으로 전환 — 안 그러면 Plaid 동기화 때 recalculateBudgets가 덮어씀
        ...(monthlyBudgetCents && { budgetSource: "USER_SET", baselineAvg3mCents: null }),
        ...(status && { status })
      }
    });

    return res.json(updatedGoal);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to modify goal" });
  }
}

export async function deleteGoal(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    const goalId = req.params.id as string; // Grab the goal ID from the URL

    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    // 1. Find the goal and verify ownership
    const existingGoal = await prisma.goal.findUnique({ where: { id: goalId } });
    if (!existingGoal) return res.status(404).json({ error: "Goal not found" });
    if (existingGoal.userId !== userId) return res.status(403).json({ error: "Unauthorized to delete this goal" });

    // 2. Delete it!
    await prisma.goal.delete({
      where: { id: goalId }
    });

    return res.json({ success: true, message: "Goal deleted successfully" });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to delete goal" });
  }
}

// // --- REUSABLE HELPER FUNCTION ---
// // This handles the math and database updates, without needing req/res!
// export const updateUserBudgets = async (userId: string) => {
//   const activeGoals = await prisma.goal.findMany({
//     where: { userId: userId, status: 'ACTIVE' }
//   });

//   let updatedCount = 0;

//   for (const goal of activeGoals) {
//     const spending = await prisma.transaction.aggregate({
//       _sum: { amountCents: true },
//       where: {
//         userId: userId,
//         category: goal.category, 
//         type: TransactionType.EXPENSE,
//         occurredAt: { gte: goal.startDate, lte: goal.endDate }
//       }
//     });

//     const totalSpent = spending._sum.amountCents || 0;

//     await prisma.goal.update({
//       where: { id: goal.id },
//       data: { currentSpentCents: totalSpent }
//     });

//     updatedCount++;
//   }
  
//   return updatedCount; // Just return the number of updated goals
// };

// export async function calculateBudgetProgress(req: Request, res: Response) {
//   try {
//     const userId = req.header("x-user-id");
//     if (!userId) {
//       return res.status(400).json({ error: "Missing x-user-id header" });
//     }

//     // Call the helper function!
//     const updatedCount = await updateUserBudgets(userId);

//     return res.json({ 
//       success: true, 
//       message: `Updated progress for ${updatedCount} goals.` 
//     });

//   } catch (error) {
//     console.error("Budget Calculation Error:", error);
//     return res.status(500).json({ error: "Failed to calculate budget progress" });
//   }
// }
