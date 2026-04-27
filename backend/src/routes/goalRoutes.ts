import { Router } from 'express';
import { getGoals, createGoal, modifyGoal, deleteGoal } from '../controllers/goalController';

const router = Router();

// GET /api/goals (List all goals)
router.get('/', getGoals);

// POST /api/goals (Create a new goal)
router.post('/', createGoal);

// PATCH /api/goals/:id (Using PATCH because we are partially updating it)
router.patch('/:id', modifyGoal);

// DELETE /api/goals/:id
router.delete('/:id', deleteGoal);

export default router;
