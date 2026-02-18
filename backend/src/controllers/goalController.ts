import { Request, Response } from 'express';
import { prisma } from "../prisma";

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
      spentPct: Math.min(spentPct, 999), // 참고용
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
    const userId = req.header("x-user-id");
    if (!userId) {
      return res.status(400).json({ error: "Missing x-user-id header" });
    }
    const {
      title,
      memo,
      icon,
      category,
      monthlyBudgetCents,
      startDate,
      endDate,
    } = req.body;

    const goal = await prisma.goal.create({
      data: {
        userId,
        title,
        memo,
        icon,
        category,
        monthlyBudgetCents: Number(monthlyBudgetCents),
        startDate: new Date(startDate),
        endDate: new Date(endDate),
      },
    });

    return res.status(201).json(goal);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: "Failed to create goal" });
  }
}

