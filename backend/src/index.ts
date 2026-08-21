import dotenv from "dotenv";
dotenv.config();

import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import goalRoutes from './routes/goalRoutes';
import transactionRoutes from "./routes/transactionRoutes";
import { generateNaggingMessage } from "./services/aiService";
import dashboardRoutes from "./routes/dashboardRoutes";
import plaidRoutes from './routes/plaidRoutes';
import userRoutes from "./routes/userRoutes";
import reportRoutes from "./routes/reportRoutes";
import authRoutes from "./routes/authRoutes";
import { requireVerifiedUser } from "./middleware/auth";


const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Allow frontend requests
app.use(express.json()); // Allow us to read JSON in requests


// --- Register Routes ---
// requireVerifiedUser: 검증된 Authorization: Bearer <jwt>가 있어야 통과.
// x-user-id 헤더만으로는 더 이상 다른 유저의 데이터에 접근할 수 없다.
// /api/auth만 예외 (로그인해서 토큰을 발급받기 전이라 아직 토큰이 없음).
app.use('/api/dashboard', requireVerifiedUser, dashboardRoutes);
app.use('/api/goals', requireVerifiedUser, goalRoutes);
app.use("/api/users", requireVerifiedUser, userRoutes);
app.use("/api/transactions", requireVerifiedUser, transactionRoutes);

app.use('/api/plaid', plaidRoutes); // 라우트별로 개별 적용 (sandbox 라우트는 유저 데이터를 다루지 않음)
app.use('/api/reports', requireVerifiedUser, reportRoutes);
app.use('/api/auth', authRoutes);

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

async function testDrive() {
  console.log("------ Gemini API 테스트 -----");
  
  const message = await generateNaggingMessage("Coffee", 10, "MILD");
  
  console.log("캐릭터 꼽 문구: ", message);
}

// testDrive();