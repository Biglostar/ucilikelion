import { Request, Response } from 'express';
import { prisma } from "../prisma";
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
// ai 합치기 전 버전
// export async function createGoalManually(req: Request, res: Response) {
//   try {
//     const userId = req.header("x-user-id");
//     if (!userId) {
//       return res.status(400).json({ error: "Missing x-user-id header" });
//     }
//     const {
//       title,
//       memo,
//       icon,
//       category,
//       monthlyBudgetCents,
//       startDate,
//       endDate,
//     } = req.body;

//     const goal = await prisma.goal.create({
//       data: {
//         userId,
//         title,
//         memo,
//         icon,
//         category,
//         monthlyBudgetCents: Number(monthlyBudgetCents),
//         startDate: new Date(startDate),
//         endDate: new Date(endDate),
//       },
//     });

//     return res.status(201).json(goal);
//   } catch (e) {
//     console.error(e);
//     return res.status(500).json({ error: "Failed to create goal" });
//   }
// }
// ai 합친 버전
export async function createGoal(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    const { title, category, monthlyBudgetCents, icon, memo, budgetSource } = req.body;

    // 이번 달 1일과 말일을 자동으로 계산
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0); // 이번달 기준
    const goal = await prisma.goal.create({
      data: {
        userId: userId as string,
        title,
        category,
        monthlyBudgetCents: Number(monthlyBudgetCents),
        icon: icon || "💰",
        memo: memo || "",
        budgetSource: budgetSource || "USER_SET",
        startDate: startOfMonth,
        endDate: endOfMonth,
        status: "ACTIVE"
      }
    });

    return res.status(201).json(goal);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Goal creation failed" });
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
