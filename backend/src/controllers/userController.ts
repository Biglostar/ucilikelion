import { Request, Response } from "express";
import { prisma } from "../prisma";

export async function deleteAccount(req: Request, res: Response) {
  try {
    const userId = req.header("x-user-id");
    if (!userId) return res.status(400).json({ error: "Missing x-user-id" });

    await prisma.monthlySummary.deleteMany({ where: { userId } });
    await prisma.report.deleteMany({ where: { userId } });
    await prisma.user.delete({ where: { id: userId } });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("Account deletion error:", error);
    return res.status(500).json({ error: "Failed to delete account" });
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