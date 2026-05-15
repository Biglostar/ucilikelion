// src/services/summaryService.ts
import { prisma } from "../prisma";
import cron from 'node-cron';
import { generateMonthlyReport } from "./aiService";
import { sendPushNotification } from "./pushService";


export async function updateMonthlySummary(
  userId: string,
  date: Date,
  amountChangeCents: number,
  type: "EXPENSE" | "INCOME" = "EXPENSE"
) {
  const year = date.getFullYear();
  const month = date.getMonth() + 1;

  return await prisma.monthlySummary.upsert({
    where: { userId_year_month: { userId, year, month } },
    update: type === "INCOME"
      ? { totalIncomeCents: { increment: amountChangeCents } }
      : { totalSpentCents: { increment: amountChangeCents } },
    create: {
      userId,
      year,
      month,
      totalSpentCents: type === "EXPENSE" && amountChangeCents > 0 ? amountChangeCents : 0,
      totalIncomeCents: type === "INCOME" && amountChangeCents > 0 ? amountChangeCents : 0,
    },
  });
}

async function syncMonthlySummary(userId: string, year: number, month: number) {
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 0, 23, 59, 59);

  const aggregations = await prisma.transaction.groupBy({
    by: ['type'],
    where: {
      userId,
      occurredAt: { gte: startDate, lte: endDate }
    },
    _sum: { amountCents: true }
  });

  const totalSpent = aggregations.find(a => a.type === 'EXPENSE')?._sum.amountCents || 0;
  const totalIncome = aggregations.find(a => a.type === 'INCOME')?._sum.amountCents || 0;

  await prisma.monthlySummary.upsert({
    where: {
      userId_year_month: { userId, year, month }
    },
    update: {
      totalSpentCents: totalSpent,
      totalIncomeCents: totalIncome
    },
    create: {
      userId,
      year,
      month,
      totalSpentCents: totalSpent,
      totalIncomeCents: totalIncome
    }
  });
}


cron.schedule('1 0 1 * *', async () => {  
  const now = new Date();
  const reportDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  const year = reportDate.getFullYear();
  const month = reportDate.getMonth() + 1;

  const users = await prisma.user.findMany({
    where: { fcmToken: { not: null } }
  });

  for (const user of users) {
    try {
      await syncMonthlySummary(user.id, year, month);
      
      const report = await generateMonthlyReport(user.id);

      await prisma.report.create({
        data: {
          userId: user.id,
          title: `${year}년 ${month}월 소비 리포트`,
          content: report,
          type: "MONTHLY_ANALYSIS",
        },
      });

      await sendPushNotification(user.fcmToken!, `${month}월 정산 리포트`, report);
      // console.log(`리포트 전송 완료: ${user.nickname}`);
    } catch (error) {
      console.error(`${user.id} 리포트 생성 실패:`, error);
    }
  }
});

// cron.schedule('1 * * * * *', () => {
//   console.log('스케줄러 작동 중...');
// });