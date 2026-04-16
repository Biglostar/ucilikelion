import { RoastLevel } from "@prisma/client";
import { GoogleGenerativeAI } from "@google/generative-ai";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "");
const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

export async function generateNaggingMessage( // 월 소비
  category: string,
  checkpoint: number,
  level: RoastLevel
): Promise<string> {
  
  const prompt = `
    Role: 차갑고 냉소적인 AI 재무 비서. (반말 사용)
    Context: 사용자의 '${category}' 예산이 ${checkpoint}% 남았음.
    Roast Level: ${level} (1:약함, 2:보통, 3:매움)

    [핵심 미션]
    사용자의 남은 예산(${checkpoint}%)에 따른 '거주 상태'를 독설에 섞어서 표현할 것. 
    예산이 적을수록 주거 환경이 처참해짐을 강조해라.

    [거주 상태 가이드라인]
    - 100%: 펜트하우스 (여유만만)
    - 75%: 일반 아파트 (슬슬 불안)
    - 50%: 좁은 고시원 (라면 취식 중)
    - 25%: 비 새는 옥탑방 (노숙 직전)
    - 0%: 길바닥 박스 (파산)

    [레벨별 말투]
    1. MILD: 비꼬지만 충고 위주. (예: "슬슬 짐 싸야할것 같아..조심해")
    2. MEDIUM: 한심하다는 듯 공격적. (예: "옥탑방 월세는 있냐?")
    3. SPICY: 매우 공격적이고 무례함. (예: "박스 주워라, 곧 노숙이다 새꺄")

    [제약 사항]
    - 반드시 한국어로 응답하되, 친구에게 말하듯 반말로 작성.
    - 공백 포함 20자 이내로 짧고 강렬하게.
    - 이모지 사용 금지.
    - 오직 대사(String)만 출력할 것.
  `;

  try {
    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text().trim();
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "통장 잔고 생각 안 하니? 작작 써."; 
  }
}

// 앱 푸쉬용 알림 문구 생성
export async function generatePushNotification(
  category: string,
  spentPct: number, 
  roastLevel: "MILD" | "MEDIUM" | "SPICY"
) {
  const prompt = `
    Role: You are a cynical, stingy financial advisor friend for a household account book app.
    Context: The user reached the ${spentPct}% remaining budget checkpoint for "${category}".
    Tone Intensity: ${roastLevel} (This is the user's chosen "Roast Level")

    Level-Specific Instructions:
    1. MILD: Sarcastic but still advice-oriented. Like a friend shaking their head. (e.g., "이러다가 예산을 넘기겠어! 조심해", "오늘부터는 조금만 더 아껴보자")
    2. MEDIUM: Direct sarcasm. Make the user feel pathetic. (e.g., "배가 불렀지, 아주?", "만수르도 생각은 하면서 돈을 쓸 텐데…")
    3. SPICY: Extremely aggressive and rude. Criticize the user's lack of self-control. (e.g., "경제관념 가출함? 엿바꿔먹음?", "ㅅ1ㅂㅅㄲ야 돌았냐? 커피에 돈을 얼마나 쳐 쓰는 거임?")

    Checkpoint Context:
    - If checkpoint is 100-75: User is doing well, but still give a light sarcastic comment to encourage them to keep it up.
    - If checkpoint is 75-50: It's the beginning of a downfall.
    - If checkpoint is 50-25: User is in the danger zone, start being more critical.
    - If checkpoint is 25-10: It's obviously a danger zone.
    - If checkpoint is 0 or less: The user is officially broke. Be most ruthless here.

    Constraints:
    - Language: Korean (close friend feel)
    - Length: Under 20 characters.
    - No emojis.
  `;

  try {
    const result = await model.generateContent(prompt);
    return result.response.text().trim();
  } catch (error) {
    console.error("AI Push Message Error:", error);
    return "작작 좀 써! 벌써 예산 다 차간다."; 
  }
}

export async function generateAiBudgetAnalysis(
  category: string,
  monthlySummaries: { month: string; totalCents: number }[]
) {
  const averageCents = monthlySummaries.reduce((acc, cur) => acc + cur.totalCents, 0) / 3;

  const prompt = `
    You are a professional financial data analyst AI.
    Task: Analyze the user's 3-month spending history for the '${category}' category and suggest a rational monthly budget.

    User Spending Data (Last 3 Months):
    ${monthlySummaries.map(s => `- ${s.month}: ${s.totalCents} USD`).join("\n")}
    Arithmetic Average: ${averageCents} USD

    Instructions:
    1. Evaluate the consistency of spending (is it increasing, decreasing, or volatile?).
    2. Recommend a "Suggested Budget" for the next month in CENTS (integer). 
    3. If there is a clear downward trend, suggest a tighter budget. If it's volatile, suggest a budget that covers the median.
    4. Provide the output strictly in JSON format.

    Output Format (Strict JSON):
    {
      "suggestedBudget": 500
    }
  `;

  try {
    const result = await model.generateContent(prompt);
    let responseText = result.response.text();

    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return { suggestedBudget: parsed.suggestedBudget };
    }
    
    throw new Error("Invalid AI Response");
  } catch (error) {
    console.error("AI Analysis Error:", error);
    return { suggestedBudget: Math.floor(averageCents) };
  }
}