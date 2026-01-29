import { Request, Response } from 'express';
import prisma from '../prisma';

export const getGoals = async (req: Request, res: Response) => {
  try {
    // 1. Get User ID
    const userId = req.headers['user-id'] as string;
    
    // 2. Fetch Goals
    const goals = await prisma.goal.findMany({
      where: { userId: userId }
    });

    // 3. Format Data for the "Energy Bar" UI
    const formattedGoals = goals.map(goal => {
      const spent = Number(goal.current_spent);
      const budget = Number(goal.monthly_budget);
      
      // Math: Calculate Remaining Percentage
      // Start from full energy bar to zero
      // If budget is 0, avoid division by zero
      let remainingPercent = 0;
      if (budget > 0) {
        remainingPercent = ((budget - spent) / budget) * 100;
      }

      // Cap the value: It can't go below 0 (even if they overspend)
      // If they overspent, the bar should just be empty (0%)
      const energyLevel = Math.max(0, remainingPercent);

      // 여기도 임의 값 설정함. Green = budget remains, Red: no budget
      let statusColor = "GREEN"; 
      if (energyLevel < 50) statusColor = "YELLOW";
      if (energyLevel < 20) statusColor = "RED"; // "Turns red" when low

      return {
        ...goal,
        current_spent: spent,    // Send numbers as normal numbers (not decimals)
        monthly_budget: budget,
        percentage: energyLevel, // This now starts at 100 and drops to 0
        status_color: statusColor
      };
    });

    res.json(formattedGoals);

  } catch (error) {
    console.error(error); // Log error for debugging
    res.status(500).json({ error: "Failed to fetch goals" });
  }
};

// Create a new Goal (For testing)
export const createGoal = async (req: Request, res: Response) => {
  try {
    const userId = req.headers['user-id'] as string;
    const { category, monthly_budget } = req.body;

    const newGoal = await prisma.goal.create({
      data: {
        userId,
        category,
        monthly_budget,
        start_date: new Date(),
        end_date: new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0),
      }
    });

    res.json(newGoal);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to create goal" });
  }
};
