import { Goal } from "@prisma/client";


export function calculateRemainingPct(currentSpent: number, budget: number): number {
  if (budget <= 0) return 0;
  const remaining = budget - currentSpent;
  return Math.max(0, (remaining / budget) * 100);
}
export function getCharacterStatus(remainingPct: number) {
  if (remainingPct > 75) return "RICH";
      else if (remainingPct > 50) return "STABLE";
      else if (remainingPct > 25) return "SURVIVING";
      else if (remainingPct > 0) return "DESPERATE";
      else return "BROKE";
}

const CHECKPOINTS = [100, 75, 50, 25, 10, 0];

/**
 * 남은 예산 비율(remainingPct) 기준으로 checkpoint 알림 상태를 다시 계산한다.
 * - 지출이 줄어 남은 비율이 다시 올라가면(삭제/수정/환급, 새 달 시작) lastAlertPct를 올려서
 *   이미 지나간 checkpoint를 다시 알릴 수 있게 한다.
 * - 새로 지나간 checkpoint가 있으면 그중 가장 낮은 값을 반환한다.
 */
export function evaluateCheckpoint(lastAlertPct: number, remainingPct: number) {
  // 현재 남은 비율 이상인 checkpoint 중 가장 작은 값 = 지금 상태에서 "이미 지나간" 경계
  const ceiling = [...CHECKPOINTS].reverse().find(cp => cp >= remainingPct) ?? 100;
  const restored = Math.max(lastAlertPct, ceiling);

  const crossed = [...CHECKPOINTS].reverse().find(cp => remainingPct <= cp && cp < restored);
  return {
    crossedCheckpoint: crossed ?? null,
    lastAlertPct: crossed ?? restored,
  };
}

export function remainingPctOf(spentCents: number, budgetCents: number) {
  if (budgetCents <= 0) return 0;
  return ((budgetCents - spentCents) / budgetCents) * 100;
}
