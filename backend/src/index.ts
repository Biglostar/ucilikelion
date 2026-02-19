import dotenv from "dotenv";
dotenv.config();

import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import dashboardRoutes from './routes/dashboardRoutes';
import goalRoutes from './routes/goalRoutes';
import transactionRoutes from "./routes/transactionRoutes";
import { generateNaggingMessage } from "./services/aiService";
import plaidRoutes from './routes/plaidRoutes';


const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Allow frontend requests
app.use(express.json()); // Allow us to read JSON in requests


// --- Register Routes ---
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/goals', goalRoutes);

app.use("/api/transactions", transactionRoutes);

app.use('/api/plaid', plaidRoutes);

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

async function testDrive() {
  console.log("------ Gemini API 테스트 -----");
  
  const message = await generateNaggingMessage("Coffee", 10, "MILD");
  
  console.log("캐릭터 꼽 문구: ", message);
}

testDrive();