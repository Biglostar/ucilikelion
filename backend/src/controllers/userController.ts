import { Request, Response } from "express";
import { Prisma, RoastLevel } from "@prisma/client";
import { prisma } from "../prisma";
import { plaidClient } from "../services/plaidService";
import { decryptPlaidToken } from "../utils/tokenCrypto";

export async function deleteAccount(req: Request, res: Response) {
  // requireVerifiedUser가 검증한 토큰의 userId만 여기 도달한다.
  const userId = req.header("x-user-id");
  if (!userId) return res.status(401).json({ error: "Authentication required" });

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { plaidAccessToken: true },
    });

    // 이미 삭제된 계정이면 성공으로 응답한다. 재시도나 오래된 토큰으로 다시
    // 호출됐을 때 클라이언트가 "삭제 실패"로 오해하지 않도록 멱등하게 처리.
    if (!user) {
      return res.status(200).json({ success: true, alreadyDeleted: true });
    }

    if (user.plaidAccessToken) {
      try {
        await plaidClient.itemRemove({ access_token: decryptPlaidToken(user.plaidAccessToken) });
      } catch (plaidError) {
        console.error("Plaid item removal failed during account deletion:", plaidError);
      }
    }

    // MonthlySummary/Report는 FK가 RESTRICT라 직접 지워야 한다. 한 트랜잭션으로
    // 묶어야 유저 삭제가 실패했을 때 히스토리만 사라지는 상태가 안 남는다.
    // (Goal/Transaction은 onDelete: Cascade)
    await prisma.$transaction([
      prisma.monthlySummary.deleteMany({ where: { userId } }),
      prisma.report.deleteMany({ where: { userId } }),
      prisma.user.delete({ where: { id: userId } }),
    ]);

    return res.status(200).json({ success: true });
  } catch (error) {
    // 조회와 삭제 사이에 다른 요청이 먼저 지운 경우도 성공으로 본다.
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2025") {
      return res.status(200).json({ success: true, alreadyDeleted: true });
    }
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