// =============================================================================
// elo.ts — ELO rating calculation
// =============================================================================

import { getEloConfig } from './live-config';

export interface EloResult {
  newWinner: number;
  newLoser: number;
}

/**
 * Calculate new ELO ratings after a match.
 *
 * Standard ELO formula:
 *   Expected score E = 1 / (1 + 10^((opponent - player) / 400))
 *   New rating = old + K * (actual - expected)
 *
 * @param winnerRating  Current rating of the winner
 * @param loserRating   Current rating of the loser
 * @param k             K-factor (optional, defaults to live config K_DEFAULT)
 * @returns             New ratings for both players
 */
export async function calculateElo(
  winnerRating: number,
  loserRating: number,
  k?: number,
): Promise<EloResult> {
  const eloConfig = await getEloConfig();
  const kFactor = k !== undefined ? k : eloConfig.K_DEFAULT;

  const expectedWinner = 1 / (1 + Math.pow(10, (loserRating - winnerRating) / 400));
  const expectedLoser = 1 / (1 + Math.pow(10, (winnerRating - loserRating) / 400));

  const newWinner = Math.max(
    eloConfig.MIN_RATING,
    Math.round(winnerRating + kFactor * (1 - expectedWinner)),
  );
  const newLoser = Math.max(
    eloConfig.MIN_RATING,
    Math.round(loserRating + kFactor * (0 - expectedLoser)),
  );

  return { newWinner, newLoser };
}

/**
 * Determine the appropriate K-factor based on the number of calibration games played.
 */
export async function getKFactor(calibrationGamesPlayed: number): Promise<number> {
  const eloConfig = await getEloConfig();
  return calibrationGamesPlayed < eloConfig.CALIBRATION_GAMES
    ? eloConfig.K_CALIBRATION
    : eloConfig.K_DEFAULT;
}
