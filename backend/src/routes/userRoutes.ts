import { Router } from "express";
import { updateFcmToken, deleteAccount } from "../controllers/userController";

const router = Router();

router.patch("/fcm-token", updateFcmToken);
router.delete("/", deleteAccount);

export default router;