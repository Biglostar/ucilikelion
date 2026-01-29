import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import dashboardRoutes from './routes/dashboardRoutes';
import goalRoutes from './routes/goalRoutes';

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Allow frontend requests
app.use(express.json()); // Allow us to read JSON in requests

// // --- TEST ROUTE ---
// app.get('/api/health', (req, res) => {
//   res.json({ status: 'OK', message: 'Server is running!' });
// });

// --- Register Routes ---
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/goals', goalRoutes);

// --- Temp Route to Create a Test User (Run this once) ---
app.post('/api/init-user', async (req, res) => {
  try {
    const user = await prisma.user.create({
      data: {
        nickname: "TestUser",
        email: "test@example.com",
        roast_level: "SPICY"
      }
    });
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: "User likely already exists" });
  }
});

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
