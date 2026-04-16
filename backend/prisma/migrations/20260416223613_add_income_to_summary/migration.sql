/*
  Warnings:

  - A unique constraint covering the columns `[googleId]` on the table `User` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "TransactionSource" AS ENUM ('MANUAL', 'PLAID');

-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "source" "TransactionSource" NOT NULL DEFAULT 'MANUAL';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "characterMessage" TEXT DEFAULT 'Hi',
ADD COLUMN     "characterStatus" TEXT NOT NULL DEFAULT 'RICH',
ADD COLUMN     "fcmToken" TEXT,
ADD COLUMN     "googleId" TEXT,
ADD COLUMN     "lastTotalAlertPct" INTEGER NOT NULL DEFAULT 100,
ADD COLUMN     "totalMonthlyBudgetCents" INTEGER NOT NULL DEFAULT 1000000;

-- CreateTable
CREATE TABLE "MonthlySummary" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "month" INTEGER NOT NULL,
    "totalSpentCents" INTEGER NOT NULL DEFAULT 0,
    "totalIncomeCents" INTEGER NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MonthlySummary_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "MonthlySummary_userId_year_month_key" ON "MonthlySummary"("userId", "year", "month");

-- CreateIndex
CREATE UNIQUE INDEX "User_googleId_key" ON "User"("googleId");

-- AddForeignKey
ALTER TABLE "MonthlySummary" ADD CONSTRAINT "MonthlySummary_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
