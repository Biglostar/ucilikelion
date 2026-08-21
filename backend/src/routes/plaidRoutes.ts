import { Router } from 'express';
import {
  createLinkToken,
  exchangePublicToken,
  syncTransactions,
  resetAndSyncTransactions,
  testSandboxLogin
} from '../controllers/plaidController';
import { requireVerifiedUser } from '../middleware/auth';

const router = Router();

// real Frontend routes - all act on a specific user's bank link, so require a verified JWT
router.get('/create_link_token', requireVerifiedUser, createLinkToken);
router.post('/create_link_token', requireVerifiedUser, createLinkToken);
router.post('/exchange_public_token', requireVerifiedUser, exchangePublicToken);
router.post('/sync', requireVerifiedUser, syncTransactions);
router.post('/reset-sync', requireVerifiedUser, resetAndSyncTransactions);

// temporary route for development - doesn't touch any user data, no auth needed
router.post('/sandbox/public_token', testSandboxLogin);

export default router;
