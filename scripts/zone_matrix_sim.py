#!/usr/bin/env python3
"""
Zone-matrix simulator for Hexbound interactive combat.

Two layers:
  1. Per-round zero-sum game (9x9: each side picks (attack, defend)) -> Nash via
     fictitious play. Pure equilibrium == "solved game" (bad). Mixed == real
     mind game (good).
  2. Full-fight Monte-Carlo with policies (naive head/chest, uniform, bot
     personalities, adaptive reader) under rule set v1 (current code) and v2
     (proposal). Skill expression = winrate gap reader vs naive.
"""
import random, itertools, sys, json
from collections import defaultdict

ZONES = ['head', 'chest', 'legs']
OPTS = list(itertools.product(ZONES, ZONES))  # (atk, def)

# ---- current code constants (balance.ts / combat.ts) ----
V1 = dict(
    ATTACK={'head': (10, 5), 'chest': (5, 0), 'legs': (2, 0)},   # offense%, crit%
    DEFENSE={'head': (0, 8), 'chest': (10, 0), 'legs': (5, 3)},  # defense%, dodge%
    MISMATCH_OFF=5, MATCH_DEF=15,
)

# ---- proposal v2 (tunable) ----
import os
V2 = dict(
    HEAD_BLOCK=float(os.environ.get('HEAD_BLOCK', 0.35)),
    HEAD_CRIT_MULT=float(os.environ.get('HEAD_CRIT_MULT', 1.8)),   # head into open zone: guaranteed crit at this mult
    HEAD_COUNTER=float(os.environ.get('HEAD_COUNTER',0.15)),     # head into block: 0 dmg, defender counters for this * his hit
    CHEST_BLOCK=float(os.environ.get('CHEST_BLOCK',0.6)),       # chest into block
    LEGS_OPEN=float(os.environ.get('LEGS_OPEN',0.85)),         # legs into open zone (and opens the enemy next round)
    LEGS_BLOCK=float(os.environ.get('LEGS_BLOCK',0.5)),        # legs into block
)

# ---- mirror fighter (L20-ish warrior) ----
F = dict(hp=700, raw=100, armor=50, crit=0.20, crit_mult=1.5, dodge=0.10, var=0.10)
MAX_ROUNDS = 15
FATIGUE_START = 10
FATIGUE_PCT = 0.10

def mitig(raw, armor):
    return raw * 100.0 / (100.0 + armor)

# ------------------------------------------------------------------ round math
def hit_v1(rng, atk, dfn, opp_atk, opp_def, rnd, F=F):
    """Expected-style single strike under current rules. Returns (dmg_to_defender, dmg_back)."""
    off, crit_b = V1['ATTACK'][atk]
    deff, dodge_b = V1['DEFENSE'][opp_def]
    if atk != opp_def: off += V1['MISMATCH_OFF']
    if atk == opp_def: deff += V1['MATCH_DEF']
    dodge = min(F['dodge'] + dodge_b / 100, 0.30)
    if rng.random() < dodge: return 0.0, 0.0
    crit = min(F['crit'] + crit_b / 100, 0.50)
    d = mitig(F['raw'] * (1 + rng.uniform(-F['var'], F['var'])), F['armor'])
    if rng.random() < crit: d *= F['crit_mult']
    d *= (1 + off / 100) * (1 - deff / 100)
    if rnd > FATIGUE_START: d *= 1 + (rnd - FATIGUE_START) * FATIGUE_PCT
    return max(1, int(d)), 0.0

def hit_v2(rng, atk, dfn, opp_atk, opp_def, rnd, opened=False, P=V2, F=F):
    """Proposal. opened=True -> defender's block ignored this round (legs effect).
    Returns (dmg_to_defender, counter_dmg_to_attacker, opens_enemy_next_round)."""
    if rng.random() < F['dodge']: return 0.0, 0.0, False
    base = mitig(F['raw'] * (1 + rng.uniform(-F['var'], F['var'])), F['armor'])
    fat = 1 + (rnd - FATIGUE_START) * FATIGUE_PCT if rnd > FATIGUE_START else 1.0
    blocked = (atk == opp_def) and not opened
    if atk == 'head':
        if blocked:
            counter = mitig(F['raw'], F['armor']) * P['HEAD_COUNTER'] * fat
            return max(1, int(base * P.get('HEAD_BLOCK', 0.0) * fat)), max(1, int(counter)), False
        return max(1, int(base * P['HEAD_CRIT_MULT'] * fat)), 0.0, False
    crit = F['crit_mult'] if rng.random() < F['crit'] else 1.0
    if atk == 'chest':
        m = P['CHEST_BLOCK'] if blocked else 1.0
        return max(1, int(base * crit * m * fat)), 0.0, False
    # legs
    m = P['LEGS_BLOCK'] if blocked else P['LEGS_OPEN']
    return max(1, int(base * crit * m * fat)), 0.0, (not blocked)

# ------------------------------------------------------------- per-round game
def expected_payoff(rules, a, b, n=4000, seed=1):
    """E[dmg A deals - dmg A receives] in one round, A plays a=(atk,def), B plays b."""
    rng = random.Random(seed)
    tot = 0.0
    for _ in range(n):
        if rules == 'v1':
            d1, _ = hit_v1(rng, a[0], a[1], b[0], b[1], 1)
            d2, _ = hit_v1(rng, b[0], b[1], a[0], a[1], 1)
            tot += d1 - d2
        else:
            d1, c1, op1 = hit_v2(rng, a[0], a[1], b[0], b[1], 1)
            d2, c2, op2 = hit_v2(rng, b[0], b[1], a[0], a[1], 1)
            # value of "opening" the enemy next round ~ extra expected dmg next round
            open_val = 0.25 * mitig(F['raw'], F['armor'])
            tot += (d1 - c1 + (open_val if op1 else 0)) - (d2 - c2 + (open_val if op2 else 0))
    return tot / n

def nash_fictitious(M, iters=20000):
    n = len(M)
    counts = [1.0] * n
    strat = [0] * n
    for _ in range(iters):
        # best response to opponent's empirical mix (symmetric zero-sum)
        tot = sum(counts)
        mix = [c / tot for c in counts]
        br = max(range(n), key=lambda i: sum(M[i][j] * mix[j] for j in range(n)))
        counts[br] += 1
    tot = sum(counts)
    return [c / tot for c in counts]

def analyse_round(rules):
    M = [[expected_payoff(rules, a, b) for b in OPTS] for a in OPTS]
    mix = nash_fictitious(M)
    atk = defaultdict(float); dfn = defaultdict(float)
    for (a, d), p in zip(OPTS, mix):
        atk[a] += p; dfn[d] += p
    # dominance check: option i dominated if exists k with M[k][j] >= M[i][j] for all j
    dominated = []
    for i, oi in enumerate(OPTS):
        for k, ok in enumerate(OPTS):
            if k != i and all(M[k][j] >= M[i][j] + 1e-9 for j in range(len(OPTS))):
                dominated.append((oi, ok)); break
    return M, mix, dict(atk), dict(dfn), dominated

# ---------------------------------------------------------------- full fights
class Policy:
    def __init__(self, name, rng): self.name, self.rng = name, rng
    def pick(self, hist, me, opp, hp_me, hp_opp): raise NotImplementedError

class Fixed(Policy):
    def __init__(self, name, rng, atk, dfn): super().__init__(name, rng); self.a, self.d = atk, dfn
    def pick(self, *_): return self.a, self.d

class Uniform(Policy):
    def pick(self, *_): return self.rng.choice(ZONES), self.rng.choice(ZONES)

class Mixed(Policy):
    """Plays a fixed mixed strategy (e.g. the Nash mix)."""
    def __init__(self, name, rng, mix): super().__init__(name, rng); self.mix = mix
    def pick(self, *_): return self.rng.choices(OPTS, weights=self.mix)[0]

class Aggressor(Policy):   # 70% head attack, repeats after landing a big hit; blocks chest mostly
    def pick(self, hist, *_):
        a = 'head' if self.rng.random() < 0.7 else self.rng.choice(['chest', 'legs'])
        d = 'chest' if self.rng.random() < 0.6 else self.rng.choice(['head', 'legs'])
        return a, d

class Turtle(Policy):      # blocks where it was last hit; attacks chest/legs
    def pick(self, hist, *_):
        last_opp_atk = hist[-1][1][0] if hist else 'chest'
        d = last_opp_atk if self.rng.random() < 0.7 else self.rng.choice(ZONES)
        a = self.rng.choice(['chest', 'legs', 'chest'])
        return a, d

class Rhythm(Policy):      # cycles head->chest->legs on attack, legs->head->chest on block
    def pick(self, hist, *_):
        i = len(hist)
        return ZONES[i % 3], ZONES[(i + 2) % 3]

class Reader(Policy):
    """Adaptive: best-responds to the opponent's empirical (atk, def) frequencies
    using the per-round payoff matrix, with a short memory window."""
    def __init__(self, name, rng, M, window=5, explore=0.1):
        super().__init__(name, rng); self.M, self.w, self.eps = M, window, explore
    def pick(self, hist, *_):
        if len(hist) < 2 or self.rng.random() < self.eps:
            return self.rng.choice(OPTS)
        recent = [h[1] for h in hist[-self.w:]]
        freq = [sum(1 for r in recent if r == o) / len(recent) for o in OPTS]
        return max(OPTS, key=lambda a: sum(self.M[OPTS.index(a)][j] * freq[j] for j in range(len(OPTS))))

def fight(rules, p1, p2, rng):
    hp = [F['hp'], F['hp']]
    opened = [False, False]       # opened[i]: fighter i's block is ignored this round
    hist1, hist2 = [], []         # (my pick, opp pick)
    for rnd in range(1, MAX_ROUNDS + 1):
        a1 = p1.pick(hist1, 0, 1, hp[0], hp[1]); a2 = p2.pick(hist2, 1, 0, hp[1], hp[0])
        hist1.append((a1, a2)); hist2.append((a2, a1))
        if rules == 'v1':
            d1, _ = hit_v1(rng, a1[0], a1[1], a2[0], a2[1], rnd); hp[1] -= d1
            if hp[1] <= 0: return 0, rnd
            d2, _ = hit_v1(rng, a2[0], a2[1], a1[0], a1[1], rnd); hp[0] -= d2
            if hp[0] <= 0: return 1, rnd
        else:
            d1, c1, o1 = hit_v2(rng, a1[0], a1[1], a2[0], a2[1], rnd, opened=opened[1])
            hp[1] -= d1; hp[0] -= c1
            if hp[1] <= 0: return 0, rnd
            if hp[0] <= 0: return 1, rnd
            d2, c2, o2 = hit_v2(rng, a2[0], a2[1], a1[0], a1[1], rnd, opened=opened[0])
            hp[0] -= d2; hp[1] -= c2
            if hp[0] <= 0: return 1, rnd
            if hp[1] <= 0: return 0, rnd
            opened = [o2, o1]
    return (0 if hp[0] / F['hp'] >= hp[1] / F['hp'] else 1), MAX_ROUNDS

def winrate(rules, mk1, mk2, n=int(os.environ.get('NFIGHTS',3000)), seed=7):
    rng = random.Random(seed)
    w = 0; rounds = 0
    for _ in range(n):
        p1, p2 = mk1(rng), mk2(rng)
        r, k = fight(rules, p1, p2, rng); w += (r == 0); rounds += k
    return w / n, rounds / n

def main():
    out = {}
    for rules in (('v2',) if os.environ.get('ONLY_V2') else ('v1', 'v2')):
        M, mix, atk, dfn, dom = analyse_round(rules)
        print(f"\n===== {rules.upper()} per-round game =====")
        print("Nash attack mix :", {k: round(v, 2) for k, v in atk.items()})
        print("Nash block mix  :", {k: round(v, 2) for k, v in dfn.items()})
        top = sorted(zip(OPTS, mix), key=lambda x: -x[1])[:4]
        print("Top joint picks :", [(o, round(p, 2)) for o, p in top])
        print("Dominated opts  :", len(dom), "of 9 ->", [f"{d[0]} < {d[1]}" for d in dom][:6])
        mk = {
            'naive head/chest': lambda r: Fixed('naive', r, 'head', 'chest'),
            'uniform': lambda r: Uniform('uni', r),
            'nash mix': lambda r: Mixed('nash', r, mix),
            'aggressor bot': lambda r: Aggressor('aggr', r),
            'turtle bot': lambda r: Turtle('turtle', r),
            'rhythm bot': lambda r: Rhythm('rhythm', r),
            'reader (adaptive)': lambda r: Reader('reader', r, M),
        }
        print(f"\n--- {rules.upper()} full fights: P1 winrate (avg rounds) ---")
        rows = {}
        for n1 in ('naive head/chest', 'nash mix', 'reader (adaptive)'):
            for n2 in mk:
                wr, rd = winrate(rules, mk[n1], mk[n2])
                rows[(n1, n2)] = (wr, rd)
                print(f"{n1:18s} vs {n2:18s}: {wr*100:5.1f}%  ({rd:4.1f} r)")
        out[rules] = dict(atk=atk, dfn=dfn, dominated=len(dom),
                          rows={f"{a}|{b}": v for (a, b), v in rows.items()})
    json.dump(out, open(sys.argv[1] if len(sys.argv) > 1 else 'zone_sim_out.json', 'w'), indent=1)

if __name__ == '__main__':
    main()
