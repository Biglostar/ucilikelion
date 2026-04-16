import { Router } from "express";
import { updateFcmToken } from "../controllers/userController";

const router = Router();

router.patch("/fcm-token", updateFcmToken);

export default router;