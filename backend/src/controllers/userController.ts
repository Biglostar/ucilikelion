import { Request, Response } from "express";
import { RoastLevel } from "@prisma/client";
import { prisma } from "../prisma";
import { plaidClient } from "../services/plaidService";

export async function deleteAccount(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    if (!userId) return res.status(400).json({ error: "Missing x-user-id" });

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { plaidAccessToken: true },
    });

    if (user?.plaidAccessToken) {
      try {
        await plaidClient.itemRemove({ access_token: user.plaidAccessToken });
      } catch (plaidError) {
        console.error("Plaid item removal failed during account deletion:", plaidError);
      }
    }

    await prisma.monthlySummary.deleteMany({ where: { userId } });
    await prisma.report.deleteMany({ where: { userId } });
    await prisma.user.delete({ where: { id: userId } });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("Account deletion error:", error);
    return res.status(500).json({ error: "Failed to delete account" });
  }
}

export async function updateRoastLevel(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    const { roastLevel } = req.body;

    if (!userId) return res.status(400).json({ error: "Missing x-user-id" });
    if (!Object.values(RoastLevel).includes(roastLevel)) {
      return res.status(400).json({ error: "Invalid roastLevel" });
    }

    await prisma.user.update({
      where: { id: userId as string },
      data: { roastLevel: roastLevel as RoastLevel },
    });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("Roast level update error:", error);
    return res.status(500).json({ error: "Failed to update roast level" });
  }
}

export async function updateFcmToken(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id"); 
    const { fcmToken } = req.body;

    if (!userId || !fcmToken) {
      return res.status(400).json({ error: "Missing userId or fcmToken" });
    }

    // DB의 User 테이블 업데이트
    await prisma.user.update({
      where: { id: userId as string },
      data: { fcmToken }
    });

    console.log(`User ${userId} token updated: ${fcmToken}`);
    return res.status(200).json({ success: true, message: "FCM Token updated successfully" });
  } catch (error) {
    console.error("Token update error:", error);
    return res.status(500).json({ error: "Failed to update token" });
  }
}