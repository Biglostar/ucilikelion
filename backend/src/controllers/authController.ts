import { Request, Response } from 'express';
import { OAuth2Client } from 'google-auth-library';
import { prisma } from '../prisma';
import { signUserToken } from '../middleware/auth';

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
    // plaidAccessToken 등 내부 필드가 클라이언트로 새어나가지 않도록 필요한 필드만 select.
    const user = await prisma.user.upsert({
      where: { email },
      update: { googleId },
      create: {
        email: email!,
        nickname: name || "New User",
        googleId,
        roastLevel: "MEDIUM",
      },
      select: { id: true, email: true, nickname: true },
    });

    const token = signUserToken(user.id);

    return res.json({ user, token, message: "Login successful" });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: "Google Auth Failed" });
  }
}