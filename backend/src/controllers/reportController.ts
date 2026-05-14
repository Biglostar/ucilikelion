import { Request, Response } from 'express';
import { prisma } from '../prisma';

export async function getReports(req: Request, res: Response) {
  const userId = req.header("x-user-id") as string;
  const { type } = req.query;

  const reports = await prisma.report.findMany({
    where: {
      userId,
      ...(type ? { type: type as string } : {}),
    },
    orderBy: { createdAt: 'desc' },
  });

  return res.json(reports);
}