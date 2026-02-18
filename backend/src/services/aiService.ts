import { RoastLevel } from "@prisma/client";
import { GoogleGenerativeAI } from "@google/generative-ai";

console.log("CHECK API KEY:", process.env.GEMINI_API_KEY ? "Loaded" : "Not Loaded");
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");
const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

export async function generateNaggingMessage(
  category: string,
  checkpoint: number,
  level: RoastLevel
): Promise<string> {
  
  const prompt = `
    Role: You are a cynical, stingy financial advisor friend for a household account book app.
    Context: The user reached the ${checkpoint}% remaining budget checkpoint for "${category}".
    Tone Intensity: ${level} (This is the user's chosen "Roast Level")

    Level-Specific Instructions:
    1. MILD: Sarcastic but still advice-oriented. Like a friend shaking their head. (e.g., "75% 남았는데 벌써 그렇게 써?")
    2. MEDIUM: Direct sarcasm. Make the user feel pathetic. (e.g., "네 통장은 이미 울고 있어.")
    3. SPICY: Extremely aggressive and rude. Criticize the user's lack of self-control. (e.g., "거지 되려고 작정했냐?")

    Checkpoint Context:
    - If checkpoint is 75-50: It's the beginning of a downfall.
    - If checkpoint is 25-10: It's a critical danger zone.
    - If checkpoint is 0 or less: The user is officially broke. Be most ruthless here.

    Constraints:
    - Language: Korean (close friend feel)
    - Length: Under 20 characters.
    - No emojis.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text().trim();
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "통장 잔고 생각 안 하니? 그만 좀 써."; 
  }
}