import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function migrateTransactionsToSummary() {

  try {
    const expenses = await prisma.transaction.findMany({
      where: { type: 'EXPENSE' }
    });


    // 1. 유저/연/월별로 합산
    const summaryData: Record<string, { userId: string, year: number, month: number, amount: number }> = {};

    for (const exp of expenses) {
      const userId = exp.userId.trim();
      const year = exp.occurredAt.getFullYear();
      const month = exp.occurredAt.getMonth() + 1;
      const key = `${userId}_${year}_${month}`;

      if (!summaryData[key]) {
        summaryData[key] = { userId, year, month, amount: 0 };
      }
      summaryData[key].amount += exp.amountCents;
    }

    // 2. 루프를 돌며 Upsert 실행
    for (const data of Object.values(summaryData)) {
      await prisma.monthlySummary.upsert({
        where: {
          userId_year_month: { 
            userId: data.userId, 
            year: data.year, 
            month: data.month 
          }
        },
        update: { totalSpentCents: data.amount },
        create: { 
          userId: data.userId, 
          year: data.year, 
          month: data.month, 
          totalSpentCents: data.amount 
        }
      });
      console.log(`완료: ${data.year}년 ${data.month}월 (User: ${data.userId.substring(0,8)}...)`);
    }

  } catch (error) {
    console.error("error:", error);
  } finally {
    await prisma.$disconnect();
  }
}

migrateTransactionsToSummary();