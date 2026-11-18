import { Request, Response } from 'express';
import { plaidClient } from '../services/plaidService';
import { prisma } from '../prisma';
import { CountryCode, Products } from 'plaid';
import { TransactionType } from '@prisma/client';
import { mapPlaidCategory } from '../utils/categoryMapper';
import { updateUserBudgets, recalculateBudgets } from './dashboardController';
import { generatePushNotification } from '../services/aiService';
import { syncMonthlySummary } from '../services/summaryService';
import { refreshCharacterState } from '../services/characterService';
import { sendPushNotification } from '../services/pushService';
import { TransactionType as PrismaTransactionType } from '@prisma/client';
import { encryptPlaidToken, decryptPlaidToken } from '../utils/tokenCrypto';

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

    // Save the permanent key to the User table (encrypted at rest)
    await prisma.user.update({
      where: { id: userId },
      data: { plaidAccessToken: encryptPlaidToken(accessToken) },
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
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    console.log(`[Plaid Sync] userId: ${userId}`);

    // Get the user's saved Plaid token
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.plaidAccessToken) {
      return res.status(400).json({ error: "Bank account not linked" });
    }
    const accessToken = decryptPlaidToken(user.plaidAccessToken);

    // Production Plaid: refresh 먼저 요청 후 fetch
    console.log(`[Plaid Sync] Calling transactionsRefresh...`);
    try {
      await plaidClient.transactionsRefresh({ access_token: accessToken });
      console.log(`[Plaid Sync] transactionsRefresh done`);
    } catch (e) {
      const code = (e as any)?.response?.data?.error_code;
      console.log(`[Plaid Sync] transactionsRefresh skipped: ${code}`);
    }

    // Fetch last 180 days with pagination
    console.log(`[Plaid Sync] Calling transactionsGet...`);
    const now = new Date();
    const startDate = new Date();
    startDate.setDate(now.getDate() - 180);
    const startDateStr = startDate.toISOString().split('T')[0];
    const endDateStr = now.toISOString().split('T')[0];

    const allTransactions: any[] = [];
    let offset = 0;
    const pageSize = 500;
    while (true) {
      const response = await plaidClient.transactionsGet({
        access_token: accessToken,
        start_date: startDateStr,
        end_date: endDateStr,
        options: { count: pageSize, offset }
      });
      allTransactions.push(...response.data.transactions);
      const total = response.data.total_transactions;
      offset += response.data.transactions.length;
      if (offset >= total) break;
    }
    console.log(`[Plaid Sync] Got ${allTransactions.length} transactions`);

    const transactions = allTransactions;
    let addedCount = 0;

    for (const pt of transactions) {
      const isExpense = pt.amount > 0;
      const type = isExpense ? TransactionType.EXPENSE : TransactionType.INCOME;
      const plaidDetailedCategory = pt.personal_finance_category?.detailed;
      const amountCents = Math.round(Math.abs(pt.amount) * 100);
      // Plaid returns date-only strings - use noon to avoid timezone shifts
      const txDate = new Date(pt.date + "T12:00:00");

      // 내부 이체(카드값 납부, 송금 등 나가는 이체) 건너뛰기
      // 들어오는 이체(TRANSFER_IN: Venmo/Zelle로 친구가 보낸 돈 등)는 수입으로 기록
      if (plaidDetailedCategory?.startsWith('TRANSFER_OUT') ||
          plaidDetailedCategory?.startsWith('LOAN_PAYMENTS_CREDIT_CARD') ||
          plaidDetailedCategory?.startsWith('BANK_FEES_')) {
        continue;
      }

      // pending→posted 전환 시 같은 거래가 다른 ID로 중복 유입 방지
      const duplicate = await prisma.transaction.findFirst({
        where: {
          userId,
          title: pt.name || "Unknown",
          amountCents,
          type,
          occurredAt: {
            gte: new Date(txDate.getTime() - 2 * 24 * 60 * 60 * 1000),
            lte: new Date(txDate.getTime() + 2 * 24 * 60 * 60 * 1000),
          }
        }
      });
      if (duplicate && duplicate.plaidTxnId !== pt.transaction_id) continue;

      const result = await prisma.transaction.upsert({
        where: { plaidTxnId: pt.transaction_id },
        update: {},
        create: {
            userId: userId,
            plaidTxnId: pt.transaction_id,
            accountId: pt.account_id,
            title: pt.name || "Unknown",
            amountCents: amountCents,
            type: type,
            category: mapPlaidCategory(plaidDetailedCategory),
            occurredAt: txDate,
          }
        });
      if (result.plaidTxnId) addedCount++;
    }

    // 실제 거래내역 기반으로 MonthlySummary 재계산 (수동 입력 포함, 순지출 = 지출 − 환급)
    const allTxns = await prisma.transaction.findMany({ where: { userId }, select: { occurredAt: true } });
    const months = new Set(allTxns.map(t => `${t.occurredAt.getFullYear()}-${t.occurredAt.getMonth() + 1}`));
    for (const key of months) {
      const [year, month] = key.split('-').map(Number);
      await syncMonthlySummary(userId, year, month);
    }

    const goalAlerts = await updateUserBudgets(userId);
    await recalculateBudgets(userId);

    // 동기화로 checkpoint를 지난 목표가 있으면 가장 심각한(남은 비율이 가장 낮은) 것 하나만 알림
    if (goalAlerts.length > 0) {
      const worst = goalAlerts.reduce((a, b) => (b.checkpoint < a.checkpoint ? b : a));
      const pushUser = await prisma.user.findUnique({ where: { id: userId }, select: { fcmToken: true, roastLevel: true } });
      if (pushUser?.fcmToken) {
        const message = await generatePushNotification(worst.category, worst.checkpoint, pushUser.roastLevel);
        sendPushNotification(pushUser.fcmToken, "지출!!", message)
          .catch(e => console.error("Push failed:", e));
      } else {
        console.warn(`[Push] user ${userId}: fcmToken 없음 — 알림 스킵 (checkpoint ${worst.checkpoint})`);
      }
    }

    // 캐릭터 상태 업데이트
    await refreshCharacterState(userId);

    res.json({ success: true, added: addedCount });
  } catch (error) {
    console.error("Sync Error:", error);
    res.status(500).json({ error: "Failed to sync transactions" });
  }
};

// Plaid 데이터 전체 삭제 후 재동기화
export const resetAndSyncTransactions = async (req: Request, res: Response) => {
  try {
    const userId = req.headers['x-user-id'] as string;
    if (!userId) return res.status(400).json({ error: "Missing x-user-id header" });

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.plaidAccessToken) {
      return res.status(400).json({ error: "Bank account not linked" });
    }

    // 모든 거래내역 삭제 (sandbox + 수동 입력 포함 전체 초기화)
    const deleted = await prisma.transaction.deleteMany({ where: { userId } });
    await prisma.monthlySummary.deleteMany({ where: { userId } });
    console.log(`[Reset Sync] Deleted ${deleted.count} transactions for ${userId}`);

    // 재동기화 요청을 기존 sync로 위임
    req.headers['x-user-id'] = userId;
    return syncTransactions(req, res);
  } catch (error) {
    console.error("Reset sync error:", error);
    return res.status(500).json({ error: "Failed to reset and sync" });
  }
};

// DEV ONLY: Generate a fake public token without a frontend UI.
// Plaid 자격 증명이 production으로 설정된 배포에서는 막는다 - 그렇지 않으면
// 인증 없이 누구나 이 앱의 Plaid 자격 증명으로 API 호출을 발생시킬 수 있다.
export const testSandboxLogin = async (req: Request, res: Response) => {
  if (process.env.PLAID_ENV === "production") {
    return res.status(404).json({ error: "Not found" });
  }
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
