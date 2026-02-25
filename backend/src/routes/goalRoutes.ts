import { Router } from 'express';
import { getGoals, createGoal, calculateBudgetProgress } from '../controllers/goalController';

const router = Router();

// GET /api/goals (List all goals)
router.get('/', getGoals);

// POST /api/goals (Create a new goal)
router.post('/', createGoal);

router.post('/calculate', calculateBudgetProgress);

export default router;
