import { Router } from 'express';
import { 
  createLinkToken, 
  exchangePublicToken, 
  syncTransactions, 
  testSandboxLogin 
} from '../controllers/plaidController';

const router = Router();

// real Frontend routes
router.post('/create_link_token', createLinkToken);
router.post('/exchange_public_token', exchangePublicToken);
router.post('/sync', syncTransactions);

// temporary route for development
router.post('/sandbox/public_token', testSandboxLogin);

export default router;
