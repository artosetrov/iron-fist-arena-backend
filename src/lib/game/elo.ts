// =============================================================================
// elo.ts — ELO rating calculation
// =============================================================================

import { ELO } from './balance';

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
 * @param k             K-factor (use ELO.K_CALIBRATION for first 10 games, ELO.K_DEFAULT after)
 * @returns             New ratings for both players
 */
export function calculateElo(
  winnerRating: number,
  loserRating: number,
  k: number = ELO.K_DEFAULT,
): EloResult {
  const expectedWinner = 1 / (1 + Math.pow(10, (loserRating - winnerRating) / 400));
  const expectedLoser = 1 / (1 + Math.pow(10, (winnerRating - loserRating) / 400));

  const newWinner = Math.max(
    ELO.MIN_RATING,
    Math.round(winnerRating + k * (1 - expectedWinner)),
  );
  const newLoser = Math.max(
    ELO.MIN_RATING,
    Math.round(loserRating + k * (0 - expectedLoser)),
  );

  return { newWinner, newLoser };
}

/**
 * Determine the appropriate K-factor based on the number of calibration games played.
 */
export function getKFactor(calibrationGamesPlayed: number): number {
  return calibrationGamesPlayed < ELO.CALIBRATION_GAMES
    ? ELO.K_CALIBRATION
    : ELO.K_DEFAULT;
}
