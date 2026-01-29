import { Router } from 'express';
import { getDashboardStatus } from '../controllers/dashboardController';

const router = Router();

// GET /api/dashboard/status
router.get('/status', getDashboardStatus);

export default router;
