/*
  Warnings:

  - You are about to drop the column `current_spent` on the `Goal` table. All the data in the column will be lost.
  - You are about to drop the column `end_date` on the `Goal` table. All the data in the column will be lost.
  - You are about to drop the column `last_alert_threshold` on the `Goal` table. All the data in the column will be lost.
  - You are about to drop the column `monthly_budget` on the `Goal` table. All the data in the column will be lost.
  - You are about to drop the column `start_date` on the `Goal` table. All the data in the column will be lost.
  - You are about to drop the column `amount` on the `Transaction` table. All the data in the column will be lost.
  - You are about to drop the column `date` on the `Transaction` table. All the data in the column will be lost.
  - You are about to drop the column `store_name` on the `Transaction` table. All the data in the column will be lost.
  - You are about to drop the column `triggered_roast` on the `Transaction` table. All the data in the column will be lost.
  - You are about to drop the column `created_at` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `roast_level` on the `User` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[plaidTxnId]` on the table `Transaction` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `endDate` to the `Goal` table without a default value. This is not possible if the table is not empty.
  - Added the required column `monthlyBudgetCents` to the `Goal` table without a default value. This is not possible if the table is not empty.
  - Added the required column `startDate` to the `Goal` table without a default value. This is not possible if the table is not empty.
  - Added the required column `title` to the `Goal` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `Goal` table without a default value. This is not possible if the table is not empty.
  - Added the required column `amountCents` to the `Transaction` table without a default value. This is not possible if the table is not empty.
  - Added the required column `occurredAt` to the `Transaction` table without a default value. This is not possible if the table is not empty.
  - Added the required column `title` to the `Transaction` table without a default value. This is not possible if the table is not empty.
  - Added the required column `type` to the `Transaction` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `Transaction` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `User` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "RoastLevel" AS ENUM ('MILD', 'MEDIUM', 'SPICY');

-- CreateEnum
CREATE TYPE "GoalStatus" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "BudgetSource" AS ENUM ('AUTO_AVG_3M', 'USER_SET');

-- CreateEnum
CREATE TYPE "TransactionType" AS ENUM ('INCOME', 'EXPENSE');

-- DropForeignKey
ALTER TABLE "Goal" DROP CONSTRAINT "Goal_userId_fkey";

-- DropForeignKey
ALTER TABLE "Transaction" DROP CONSTRAINT "Transaction_userId_fkey";

-- AlterTable
ALTER TABLE "Goal" DROP COLUMN "current_spent",
DROP COLUMN "end_date",
DROP COLUMN "last_alert_threshold",
DROP COLUMN "monthly_budget",
DROP COLUMN "start_date",
ADD COLUMN     "baselineAvg3mCents" INTEGER,
ADD COLUMN     "budgetSource" "BudgetSource" NOT NULL DEFAULT 'AUTO_AVG_3M',
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "currentSpentCents" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "endDate" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "icon" TEXT,
ADD COLUMN     "isSelected" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "lastAlertPct" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "memo" TEXT,
ADD COLUMN     "monthlyBudgetCents" INTEGER NOT NULL,
ADD COLUMN     "startDate" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "status" "GoalStatus" NOT NULL DEFAULT 'ACTIVE',
ADD COLUMN     "title" TEXT NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "Transaction" DROP COLUMN "amount",
DROP COLUMN "date",
DROP COLUMN "store_name",
DROP COLUMN "triggered_roast",
ADD COLUMN     "accountId" TEXT,
ADD COLUMN     "amountCents" INTEGER NOT NULL,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "isFixed" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "note" TEXT,
ADD COLUMN     "occurredAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "plaidTxnId" TEXT,
ADD COLUMN     "title" TEXT NOT NULL,
ADD COLUMN     "type" "TransactionType" NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "created_at",
DROP COLUMN "roast_level",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "roastLevel" "RoastLevel" NOT NULL DEFAULT 'MILD',
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL;

-- CreateIndex
CREATE INDEX "Goal_userId_idx" ON "Goal"("userId");

-- CreateIndex
CREATE INDEX "Goal_userId_category_idx" ON "Goal"("userId", "category");

-- CreateIndex
CREATE UNIQUE INDEX "Transaction_plaidTxnId_key" ON "Transaction"("plaidTxnId");

-- CreateIndex
CREATE INDEX "Transaction_userId_occurredAt_idx" ON "Transaction"("userId", "occurredAt");

-- CreateIndex
CREATE INDEX "Transaction_userId_category_idx" ON "Transaction"("userId", "category");

-- AddForeignKey
ALTER TABLE "Goal" ADD CONSTRAINT "Goal_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
