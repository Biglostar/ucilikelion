// src/services/summaryService.ts
import { Prisma } from "@prisma/client";
import { prisma } from "../prisma";
import cron from 'node-cron';
import { generateMonthlyReport } from "./aiService";
import { sendPushNotification } from "./pushService";


type DbClient = Prisma.TransactionClient | typeof prisma;

// 'income' 카테고리가 아닌 수입은 환급(친구가 보낸 더치페이, 반품 등)으로 보고 지출에서 차감한다
export function isRefund(t: { type: string; category: string }) {
  return t.type === "INCOME" && t.category !== "income";
}

/**
 * 해당 월의 거래내역으로 MonthlySummary를 다시 계산한다.
 * - totalSpentCents  = 지출 − 환급 (순지출, 0 미만이면 0)
 * - totalIncomeCents = 'income' 카테고리 수입만
 * 트랜잭션 안에서 부를 때는 tx를 넘긴다.
 */
export async function syncMonthlySummary(userId: string, year: number, month: number, db: DbClient = prisma) {
  const startDate = new Date(year, month - 1, 1);
  const endDate = new Date(year, month, 0, 23, 59, 59, 999);

  const groups = await db.transaction.groupBy({
    by: ['type', 'category'],
    where: {
      userId,
      occurredAt: { gte: startDate, lte: endDate }
    },
    _sum: { amountCents: true }
  });

  let expense = 0, refund = 0, income = 0;
  for (const g of groups) {
    const sum = g._sum.amountCents || 0;
    if (g.type === 'EXPENSE') expense += sum;
    else if (isRefund(g)) refund += sum;
    else income += sum;
  }
  const totalSpent = Math.max(0, expense - refund);

  return db.monthlySummary.upsert({
    where: {
      userId_year_month: { userId, year, month }
    },
    update: {
      totalSpentCents: totalSpent,
      totalIncomeCents: income
    },
    create: {
      userId,
      year,
      month,
      totalSpentCents: totalSpent,
      totalIncomeCents: income
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

      const report = await generateMonthlyReport(user.id, year, month);

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