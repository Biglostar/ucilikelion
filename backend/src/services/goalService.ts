import { Goal } from "@prisma/client";


export function calculateRemainingPct(currentSpent: number, budget: number): number {
  if (budget <= 0) return 0;
  const remaining = budget - currentSpent;
  return Math.max(0, (remaining / budget) * 100);
}
// 나중에 로직 바꾸기 (캐릭터 갯수랑 체크 포인트 매치)
export function getCharacterStatus(remainingPct: number) {
  if (remainingPct > 50) return "RICH";
  if (remainingPct > 10) return "NORMAL";
  return "POOR";
}

export function getPassedCheckpoint(lastAlertPct: number, currentPct: number): number | "OVER_BUDGET" | null {
  // 예산 초과, 매번 알림
  if (currentPct <= 0) {
    return "OVER_BUDGET";
  }

  //새로운 체크포인트를 통과하는 순간마다 (75, 50, 25, 10, 0)
  const checkpoints = [75, 50, 25, 10, 0];
  const passed = checkpoints.find(cp => currentPct <= cp && cp < lastAlertPct);
  
  return passed !== undefined ? passed : null;
}