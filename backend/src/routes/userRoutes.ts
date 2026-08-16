import { Router } from "express";
import { updateFcmToken, updateRoastLevel, deleteAccount } from "../controllers/userController";
import { requireVerifiedUser } from "../middleware/auth";

const router = Router();

router.patch("/fcm-token", updateFcmToken);
router.patch("/roast-level", updateRoastLevel);
// 계정 삭제는 되돌릴 수 없으므로 x-user-id fallback 없이 검증된 JWT만 허용.
router.delete("/", requireVerifiedUser, deleteAccount);

export default router;