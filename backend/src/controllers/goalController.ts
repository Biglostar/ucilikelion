import { Request, Response } from 'express';
import { prisma } from "../prisma";
import { generateAiBudgetAnalysis } from '../services/aiService';

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

export async function getAiSuggestedBudget(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    const { category } = req.query;

    if (!userId || !category) return res.status(400).json({ error: "Missing params" });

    const now = new Date();
    //3, 2, 1달 전으로 계산
    const months = [3, 2, 1].map(i => {
      const date = new Date(now.getFullYear(), now.getMonth() - i, 1);
      return {
        start: date,
        end: new Date(date.getFullYear(), date.getMonth() + 1, 0),
        label: `${date.getMonth() + 1}월`
      };
    });

    const monthlySummaries = await Promise.all(
      months.map(async (m) => {
        const aggregate = await prisma.transaction.aggregate({
          where: {
            userId,
            category: category as string,
            type: "EXPENSE",
            occurredAt: { gte: m.start, lte: m.end }
          },
          _sum: { amountCents: true }
        });
        return { month: m.label, totalCents: aggregate._sum.amountCents || 0 };
      })
    );

    const user = await prisma.user.findUnique({ where: { id: userId } });

    const aiSuggestion = await generateAiBudgetAnalysis(
      category as string,
      monthlySummaries
    );

    return res.json(aiSuggestion);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "ai 예산 계산 에러" });
  }
}