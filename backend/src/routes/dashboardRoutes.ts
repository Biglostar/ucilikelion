import { Router } from "express";
import { getDashboardData, refreshCharacterMessage } from "../controllers/dashboardController";

const router = Router();

router.get("/", getDashboardData);
router.post("/refresh-message", refreshCharacterMessage);

export default router;
