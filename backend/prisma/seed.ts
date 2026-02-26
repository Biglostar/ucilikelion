import { PrismaClient, RoastLevel, TransactionType, GoalStatus, BudgetSource } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Clean up existing data (to prevent from crashing)
  await prisma.transaction.deleteMany();
  await prisma.goal.deleteMany();
  await prisma.user.deleteMany();

  // 1. Create user
  const user = await prisma.user.create({
    data: {
      email: 'test@example.com',
      nickname: 'testUser',
      roastLevel: RoastLevel.MILD,
    },
  });

  // 2. Create goals
  const goal = await prisma.goal.create({
    data: {
      userId: user.id,
      title: '카페 지출 줄이기',
      memo: '이달엔 커피 줄이기!',
      icon: 'coffee',
      category: 'cafe',
      monthlyBudgetCents: 5000,
      currentSpentCents: 1200,
      isSelected: true,
      status: GoalStatus.ACTIVE,
      lastAlertPct: 25,
      budgetSource: BudgetSource.AUTO_AVG_3M,
      baselineAvg3mCents: 5000,
      startDate: new Date('2026-01-01'),
      endDate: new Date('2026-01-31'),
    },
  });

  // 3. Create transactions
  await prisma.transaction.createMany({
    data: [
      {
        userId: user.id,
        title: '스타벅스 아메리카노',
        amountCents: 5,
        type: TransactionType.EXPENSE,
        category: 'cafe',
        occurredAt: new Date('2026-01-10'),
        isFixed: false,
      },
      {
        userId: user.id,
        title: 'omomo matcha',
        amountCents: 7,
        type: TransactionType.EXPENSE,
        category: 'cafe',
        occurredAt: new Date('2026-01-14'),
        isFixed: false,
      },
      {
        userId: user.id,
        title: '용돈',
        amountCents: 1000,
        type: TransactionType.INCOME,
        category: 'allowance',
        occurredAt: new Date('2026-01-01'),
        isFixed: true,
      },
    ],
  });

  console.log('Seed completed');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
