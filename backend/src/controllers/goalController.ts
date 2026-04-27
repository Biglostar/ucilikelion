import { Request, Response } from 'express';
import { prisma } from "../prisma";
import { generateAiBudgetAnalysis } from '../services/aiService';
// import { generateAiBudgetAnalysis } from '../services/aiService';
// import { TransactionType } from '@prisma/client';

export async function getGoals(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    if (!userId) {
      return res.status(400).json({ error: "Missing x-user-id header" });
    }

    const goals = await prisma.goal.findMany({
      where: { userId },
      orderBy: { createdAt: "desc" },
    });

    // 게이지바 계산 붙여서 반환
    const withGauge = goals.map((g: any) => {
      const budget = g.monthlyBudgetCents;

      // budget이 0이면 remaining을 0
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
      const overBudget = g.currentSpentCents >= budget;

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

    if (budgetSource === "AUTO_AVG_3M") {
      const now = new Date();
      const last3Months = [];
      for (let i = 1; i <= 3; i++) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        last3Months.push({ year: d.getFullYear(), month: d.getMonth() + 1 });
      }

      const historySummaries = await prisma.monthlySummary.findMany({
        where: {
          userId,
          OR: last3Months
        }
      });

      if (historySummaries.length > 0) {
        const totalSum = historySummaries.reduce((sum, s) => sum + s.totalSpentCents, 0);
        monthlyBudgetCents = Math.floor(totalSum / historySummaries.length);
      } else {
        monthlyBudgetCents = 200000; //default
      }
    }

    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    const goal = await prisma.goal.create({
      data: {
        userId,
        title,
        category,
        monthlyBudgetCents: Number(monthlyBudgetCents),
        baselineAvg3mCents: budgetSource === "AUTO_AVG_3M" ? Number(monthlyBudgetCents) : null,
        icon: icon || "💰",
        memo: memo || "",
        budgetSource: budgetSource || "USER_SET",
        status: status || "ACTIVE", 
        startDate: startOfMonth,
        endDate: endOfMonth,
      }
    });

    return res.status(201).json(goal);
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

    // 3. Update only the fields that were provided
    const updatedGoal = await prisma.goal.update({
      where: { id: goalId },
      data: {
        ...(title && { title }),
        ...(category && { category }),
        ...(monthlyBudgetCents && { monthlyBudgetCents: Number(monthlyBudgetCents) }),
        ...(icon && { icon }),
        ...(memo !== undefined && { memo }),
        ...(budgetSource && { budgetSource }),
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
