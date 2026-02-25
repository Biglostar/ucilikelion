import { Request, Response } from 'express';
import { plaidClient } from '../services/plaidService';
import { prisma } from '../prisma';
import { CountryCode, Products } from 'plaid';
import { TransactionType } from '@prisma/client';
import { mapPlaidCategory } from '../utils/categoryMapper';
import { updateUserBudgets } from './goalController';

// Dev only
import { Products as PlaidProducts } from 'plaid';

// 1. Create Link Token (Frontend will call this when user clicks "Connect Bank")
export const createLinkToken = async (req: Request, res: Response) => {
  try {
    const userId = req.headers['user-id'] as string;

    const response = await plaidClient.linkTokenCreate({
      user: { client_user_id: userId },
      client_name: 'Kkop-jumoney',
      products: [Products.Transactions],
      country_codes: [CountryCode.Us],
      language: 'en',
    });

    res.json(response.data);
  } catch (error) {
    console.error("Link Token Error:", error);
    res.status(500).json({ error: "Failed to create link token" });
  }
};

// 2. Exchange Public Token
export const exchangePublicToken = async (req: Request, res: Response) => {
  try {
    const userId = req.headers['user-id'] as string;
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
    const userId = req.headers['user-id'] as string;

    // Get the user's saved Plaid token
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.plaidAccessToken) {
      return res.status(400).json({ error: "Bank account not linked" });
    }

    // Fetch last 30 days
    const now = new Date();
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(now.getDate() - 30);

    const response = await plaidClient.transactionsGet({
      access_token: user.plaidAccessToken,
      start_date: thirtyDaysAgo.toISOString().split('T')[0],
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
    // --- NEW LINE: Instantly recalculate budgets based on new data ---
    await updateUserBudgets(userId);

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
