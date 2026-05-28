import { Router } from "express";
import { updateFcmToken, updateRoastLevel } from "../controllers/userController";

const router = Router();

router.patch("/fcm-token", updateFcmToken);
router.patch("/roast-level", updateRoastLevel);

export default router;