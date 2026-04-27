import { Request, Response } from 'express';
import { OAuth2Client } from 'google-auth-library';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export async function googleLogin(req: Request, res: Response) {
  const { idToken } = req.body;

  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    if (!payload) return res.status(400).send("Invalid token");

    const { sub: googleId, email, name } = payload;

    // 유저 찾기
    const user = await prisma.user.upsert({
      where: { email },
      update: { googleId },
      create: {
        email: email!,
        nickname: name || "New User",
        googleId,
        roastLevel: "MEDIUM",
      },
    });

    return res.json({ user, message: "Login successful" });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: "Google Auth Failed" });
  }
}