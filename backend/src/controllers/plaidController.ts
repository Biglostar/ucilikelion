import { Request, Response } from 'express';
import { plaidClient } from '../services/plaidService';
import { prisma } from '../prisma';
import { CountryCode, Products } from 'plaid';
import { TransactionType } from '@prisma/client';
import { mapPlaidCategory } from '../utils/categoryMapper';
import { updateUserBudgets } from './dashboardController';
import { determineStatus } from './transactionController';
import { generateNaggingMessage } from '../services/aiService';

// Dev only
import { Products as PlaidProducts } from 'plaid';

// 1. Create Link Token (Frontend will call this when user clicks "Connect Bank")
export const createLinkToken = async (req: Request, res: Response) => {
  try {
    const userId = req.headers['x-user-id'] as string;

    const response = await plaidClient.linkTokenCreate({
      user: { client_user_id: userId },
      client_name: 'Kkop-jumoney',
      products: [Products.Transactions],
      country_codes: [CountryCode.Us],
      language: 'en',
    });

    res.json({ linkToken: response.data.link_token });
  } catch (error) {
    console.error("Link Token Error:", error);
    res.status(500).json({ error: "Failed to create link token" });
  }
};

// 2. Exchange Public Token
export const exchangePublicToken = async (req: Request, res: Response) => {
  try {
    const userId = req.headers['x-user-id'] as string;
    const { public_token } = req.body;

    const response = await plaidClient.itemPublicTokenExchange({
      public_token,
    });

    const accessToken = response.data.access_token;

    // Save the permanent key to the User table
    await prisma.user.update({
      where: { id: userId },
      data: { plaidAccessToken: accessToken },
    });

    res.json({ success: true, message: "Bank linked successfully!" });
  } catch (error) {
    console.error("Exchange Error:", error);
    res.status(500).json({ error: "Failed to exchange token" });
  }
};

// 3. Sync Transactions (Fetch from Plaid and save to DB)
export const syncTransactions = async (req: Request, res: Response) => {
  try {
    const userId = req.headers['x-user-id'] as string;

    // Get the user's saved Plaid token
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.plaidAccessToken) {
      return res.status(400).json({ error: "Bank account not linked" });
    }

    // Production Plaid: refresh 먼저 요청 후 fetch
    try {
      await plaidClient.transactionsRefresh({ access_token: user.plaidAccessToken });
    } catch (e) {
      // refresh 실패해도 계속 진행 (이미 준비됐을 수 있음)
      console.log("transactionsRefresh skipped:", (e as any)?.response?.data?.error_code);
    }

    // Fetch last 90 days
    const now = new Date();
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(now.getDate() - 90);

    const response = await plaidClient.transactionsGet({
      access_token: user.plaidAccessToken,
      start_date: ninetyDaysAgo.toISOString().split('T')[0],
      end_date: now.toISOString().split('T')[0],
    });

    const transactions = response.data.transactions;
    let addedCount = 0;

    for (const pt of transactions) {
      // Prevent duplicates using the unique Plaid ID
      const existing = await prisma.transaction.findUnique({
        where: { plaidTxnId: pt.transaction_id }
      });

      if (!existing) {
        // Plaid amounts: Positive = Expense, Negative = Income
        const isExpense = pt.amount > 0;
        const type = isExpense ? TransactionType.EXPENSE : TransactionType.INCOME;
        const plaidDetailedCategory = pt.personal_finance_category?.detailed;
        
        // Convert to cents (e.g., $5.50 -> 550)
        const amountCents = Math.round(Math.abs(pt.amount) * 100);

        await prisma.transaction.create({
          data: {
            userId: userId,
            plaidTxnId: pt.transaction_id,
            accountId: pt.account_id,
            title: pt.name || "Unknown",
            amountCents: amountCents,
            type: type,
            category: mapPlaidCategory(plaidDetailedCategory),
            occurredAt: new Date(pt.date),
          }
        });
        addedCount++;
      }
    }
    await updateUserBudgets(userId);

    // 캐릭터 상태 업데이트
    const updatedUser = await prisma.user.findUnique({
      where: { id: userId },
      select: { totalMonthlyBudgetCents: true, roastLevel: true, characterStatus: true }
    });

    if (updatedUser && updatedUser.totalMonthlyBudgetCents > 0) {
      const now2 = new Date();
      const summary = await prisma.monthlySummary.findUnique({
        where: { userId_year_month: { userId, year: now2.getFullYear(), month: now2.getMonth() + 1 } }
      });
      const totalSpent = summary?.totalSpentCents ?? 0;
      const totalRemainingPct = ((updatedUser.totalMonthlyBudgetCents - totalSpent) / updatedUser.totalMonthlyBudgetCents) * 100;
      const newStatus = determineStatus(totalRemainingPct);

      if (newStatus !== updatedUser.characterStatus) {
        const characterMsg = await generateNaggingMessage("monthly_progress", Math.floor(totalRemainingPct), updatedUser.roastLevel);
        await prisma.user.update({
          where: { id: userId },
          data: { characterStatus: newStatus, characterMessage: characterMsg }
        });
      }
    }

    res.json({ success: true, added: addedCount });
  } catch (error) {
    console.error("Sync Error:", error);
    res.status(500).json({ error: "Failed to sync transactions" });
  }
};

// DEV ONLY: Generate a fake public token without a frontend UI
export const testSandboxLogin = async (req: Request, res: Response) => {
  try {
    const response = await plaidClient.sandboxPublicTokenCreate({
      institution_id: 'ins_109508', // Plaid's test bank ID (First Platypus Bank)
      initial_products: [PlaidProducts.Transactions],
    });
    
    res.json({ public_token: response.data.public_token });
  } catch (error) {
    res.status(500).json({ error: "Sandbox trick failed" });
  }
};
