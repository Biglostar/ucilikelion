// import { OAuth2Client } from 'google-auth-library';
// const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// export async function googleLogin(req: Request, res: Response) {
//   const { idToken } = req.body; // 프론트에서 보낸 토큰

//   try {
//     // 1. Google 토큰 검증
//     const ticket = await client.verifyIdToken({
//       idToken,
//       audience: process.env.GOOGLE_CLIENT_ID,
//     });
//     const payload = ticket.getPayload();
//     if (!payload) return res.status(400).send("Invalid token");

//     const { sub: googleId, email, name } = payload;

//     // 2. DB에서 유저 찾기 또는 생성 (Upsert)
//     const user = await prisma.user.upsert({
//       where: { email },
//       update: { googleId },
//       create: {
//         email: email!,
//         nickname: name || "New User",
//         googleId,
//         roastLevel: 3, // 기본값 설정
//       },
//     });

//     // 3. 이제 이 유저의 ID를 세션이나 JWT에 담아 응답합니다.
//     return res.json({ user, message: "Login successful" });
//   } catch (error) {
//     console.error(error);
//     return res.status(500).json({ error: "Google Auth Failed" });
//   }
// }