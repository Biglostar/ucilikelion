import { Router } from 'express';
import { getGoals, createGoal, getAiSuggestedBudget } from '../controllers/goalController';

const router = Router();
router.get("/suggested-budget", getAiSuggestedBudget);

// GET /api/goals (List all goals)
router.get('/', getGoals);

// POST /api/goals (Create a new goal)

router.post('/', createGoal);
export default router;
