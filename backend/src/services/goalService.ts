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

export function getPassedCheckpoint(lastAlertPct: number, currentPct: number): number | "OVER_BUDGET" | null {
  // 예산 초과, 매번 알림
  if (currentPct <= 0) {
    return "OVER_BUDGET";
  }

  const checkpoints = [75, 50, 25, 10, 0];
  const passed = checkpoints.find(cp => currentPct <= cp && cp < lastAlertPct);
  
  return passed !== undefined ? passed : null;
}