// src/services/summaryService.ts
import { prisma } from "../prisma";

export async function updateMonthlySummary(
  userId: string,
  date: Date,
  amountChangeCents: number
) {
  const year = date.getFullYear();
  const month = date.getMonth() + 1;

  return await prisma.monthlySummary.upsert({
    where: {
      userId_year_month: {
        userId,
        year,
        month,
      },
    },
    update: {
      totalSpentCents: { increment: amountChangeCents },
    },
    create: {
      userId,
      year,
      month,
      totalSpentCents: amountChangeCents > 0 ? amountChangeCents : 0,
    },
  });
}