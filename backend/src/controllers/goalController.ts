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

