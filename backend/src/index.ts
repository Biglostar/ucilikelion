import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // Allow frontend requests
app.use(express.json()); // Allow us to read JSON in requests

// --- TEST ROUTE ---
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running!' });
});

// --- EXAMPLE: Create User Route ---
// POST /api/users
app.post('/api/users', async (req, res) => {
  try {
    const { nickname, email } = req.body;
    
    const newUser = await prisma.user.create({
      data: {
        nickname,
        email,
        roast_level: "MILD"
      }
    });

    res.json(newUser);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Failed to create user' });
  }
});

// Start Server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
