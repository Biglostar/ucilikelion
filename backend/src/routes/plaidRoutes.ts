import { Router } from 'express';
import {
  createLinkToken,
  exchangePublicToken,
  syncTransactions,
  resetAndSyncTransactions,
  testSandboxLogin
} from '../controllers/plaidController';

const router = Router();

// real Frontend routes
router.get('/create_link_token', createLinkToken);
router.post('/create_link_token', createLinkToken);
router.post('/exchange_public_token', exchangePublicToken);
router.post('/sync', syncTransactions);
router.post('/reset-sync', resetAndSyncTransactions);

// temporary route for development
router.post('/sandbox/public_token', testSandboxLogin);

export default router;
