import { Router } from "express";
import { updateFcmToken, updateRoastLevel, deleteAccount } from "../controllers/userController";

const router = Router();

// requireVerifiedUser는 index.ts에서 이 라우터 전체에 이미 적용됨.
router.patch("/fcm-token", updateFcmToken);
router.patch("/roast-level", updateRoastLevel);
router.delete("/", deleteAccount);

export default router;