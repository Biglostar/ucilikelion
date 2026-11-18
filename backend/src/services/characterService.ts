import { prisma } from "../prisma";
import { generateNaggingMessage } from "./aiService";
import { evaluateCheckpoint, getCharacterStatus, remainingPctOf } from "./goalService";

/**
 * 이번 달 순지출(환급 차감) 기준으로 캐릭터 상태와 말풍선을 갱신한다.
 * 거래 생성/수정/삭제, Plaid 동기화 후 DB 트랜잭션 밖에서 호출할 것.
 * 상태가 바뀌었거나 전체 예산 checkpoint를 새로 지났을 때만 Gemini를 호출한다.
 */
export async function refreshCharacterState(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { roastLevel: true, characterStatus: true, lastTotalAlertPct: true, totalMonthlyBudgetCents: true }
  });
  if (!user || user.totalMonthlyBudgetCents <= 0) return;

  const now = new Date();
  const summary = await prisma.monthlySummary.findUnique({
    where: { userId_year_month: { userId, year: now.getFullYear(), month: now.getMonth() + 1 } }
  });

  const remainingPct = remainingPctOf(summary?.totalSpentCents ?? 0, user.totalMonthlyBudgetCents);
  const { crossedCheckpoint, lastAlertPct } = evaluateCheckpoint(user.lastTotalAlertPct, remainingPct);
  const newStatus = getCharacterStatus(remainingPct);

  const needsMessage = newStatus !== user.characterStatus || crossedCheckpoint !== null;
  if (!needsMessage && lastAlertPct === user.lastTotalAlertPct) return;

  const characterMessage = needsMessage
    ? await generateNaggingMessage("monthly_progress", crossedCheckpoint ?? Math.floor(remainingPct), user.roastLevel)
    : undefined;

  await prisma.user.update({
    where: { id: userId },
    data: { characterStatus: newStatus, lastTotalAlertPct: lastAlertPct, characterMessage }
  });
}
