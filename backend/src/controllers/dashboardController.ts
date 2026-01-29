import { Request, Response } from 'express';
import prisma from '../prisma';

export const getDashboardStatus = async (req: Request, res: Response) => {
  try {
    // 1. Get the User ID (For now, simulate a logged-in user)
    const userId = req.headers['user-id'] as string; 

    if (!userId) {
      return res.status(400).json({ error: "User ID missing in headers" });
    }

    // 2. Calculate Total Spent This Month
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    
    // Sum up all transactions for this user this month
    const aggregate = await prisma.transaction.aggregate({
      _sum: {
        amount: true,
      },
      where: {
        userId: userId,
        date: {
          gte: startOfMonth,
        },
      },
    });

    const totalSpent = aggregate._sum.amount || 0;

    // 3. Determine Character Status (임의 값으로 설정함. 수정 필요)
    let characterStatus = "NORMAL";
    if (Number(totalSpent) < 100000) characterStatus = "RICH";
    if (Number(totalSpent) > 1000000) characterStatus = "BEGGAR";

    // 4. Send Response
    res.json({
      total_spent: totalSpent,
      character_status: characterStatus,
      month: now.getMonth() + 1
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to fetch dashboard status" });
  }
};
