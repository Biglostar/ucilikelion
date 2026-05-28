import { Router } from "express";
import { updateFcmToken, updateRoastLevel, deleteAccount } from "../controllers/userController";

const router = Router();

router.patch("/fcm-token", updateFcmToken);
router.patch("/roast-level", updateRoastLevel);
router.delete("/", deleteAccount);

export default router;