#!/usr/bin/env python3
"""
Dice combat simulator — Hexbound "4 dice" proposal.

Each fighter: attack die + defense die, d6, base faces 2×head 2×chest 2×legs.
Round: all 4 dice rolled. Simultaneous decision: each side may spend Focus to
  - REROLL one own die (cost R)        or
  - TURN one own die to a chosen face (cost T, must exist on that die)
Then strikes resolve by initiative. Attack blocked if zone == opp defense zone
(unless WALL face on defense: blocks everything; or defender opened by legs).

Attack faces: head (crit xHEAD), chest (x1), legs (xLEGS, opens defender next
round), gold (zone head, crit xGOLD). Blocked = 0 dmg.
Combos: STANCE (my atk zone == my def zone) -> +1 Focus.
        OMEN (all four zones equal) -> all strikes this round crit.
Focus: start F0, +1 per round, cap FMAX.
"""
import random, sys, os
from statistics import mean

HEAD, CHEST, LEGS = 'head', 'chest', 'legs'
ZONES = [HEAD, CHEST, LEGS]
P = dict(HEAD=1.6, LEGS=0.9, GOLD=1.9, WALL=0.5, R=2, T=4, F0=1, FMAX=5, HP=100, DMG=13,
         MAX_ROUNDS=15, FATIGUE_START=10, FATIGUE=0.15)
for k in list(P):
    if k in os.environ: P[k] = type(P[k])(os.environ[k])

def face(z, kind='plain'): return (z, kind)
BASE = [face(HEAD), face(HEAD), face(CHEST), face(CHEST), face(LEGS), face(LEGS)]

class F:
    def __init__(s, name, policy, atk=None, dfn=None, hp=None, dmg=None, agi=10):
        s.name, s.policy = name, policy
        s.atk = list(atk or BASE); s.dfn = list(dfn or BASE)
        s.hp = s.maxhp = hp or P['HP']; s.dmg = dmg or P['DMG']; s.agi = agi
        s.focus = P['F0']; s.opened = False
        s.stats = dict(rerolls=0, turns=0, stance=0)

def strike_value(a_face, d_face, opened):
    z, kind = a_face
    if not opened and d_face[0] == z: return 0.0, False
    wall = (not opened and d_face[1] == 'wall')
    m, o = _open_value(a_face)
    return (m * P['WALL'], False) if wall else (m, o)

def _open_value(a_face):
    z, kind = a_face
    if kind == 'gold': return P['GOLD'], False
    if z == HEAD: return P['HEAD'], False
    if z == LEGS: return P['LEGS'], True
    return 1.0, False

# ---------------------------------------------------------------- policies
def never(me, opp, my, op, rng): return None

def random_spend(me, opp, my, op, rng):
    if me.focus >= P['R'] and rng.random() < 0.5:
        return ('reroll', rng.choice(['atk', 'dfn']), None)
    return None

def smart(me, opp, my, op, rng):
    """Greedy one-step EV. Considers: reroll atk, reroll dfn, turn atk, turn dfn."""
    a, d = my; oa, od = op
    base_out, _ = strike_value(a, od, opp.opened)
    base_in, _ = strike_value(oa, d, me.opened)
    best, best_gain = None, 0.15  # threshold: don't spend for crumbs
    # reroll attack
    if me.focus >= P['R']:
        ev = mean(strike_value(f, od, opp.opened)[0] for f in me.atk)
        g = (ev - base_out) * me.dmg / P['R']
        if g > best_gain: best, best_gain = ('reroll', 'atk', None), g
        ev_in = mean(strike_value(oa, f, me.opened)[0] for f in me.dfn)
        g = (base_in - ev_in) * opp.dmg / P['R']
        if g > best_gain: best, best_gain = ('reroll', 'dfn', None), g
    if me.focus >= P['T']:
        bf = max(me.atk, key=lambda f: strike_value(f, od, opp.opened)[0])
        g = (strike_value(bf, od, opp.opened)[0] - base_out) * me.dmg / P['T']
        if g > best_gain: best, best_gain = ('turn', 'atk', bf), g
        bd = min(me.dfn, key=lambda f: strike_value(oa, f, me.opened)[0])
        g = (base_in - strike_value(oa, bd, me.opened)[0]) * opp.dmg / P['T']
        if g > best_gain: best, best_gain = ('turn', 'dfn', bd), g
    return best

def apply(me, act, my, rng):
    if not act: return my
    kind, which, target = act
    a, d = my
    if kind == 'reroll':
        me.focus -= P['R']; me.stats['rerolls'] += 1
        if which == 'atk': a = rng.choice(me.atk)
        else: d = rng.choice(me.dfn)
    else:
        me.focus -= P['T']; me.stats['turns'] += 1
        if which == 'atk': a = target
        else: d = target
    return (a, d)

def fight(f1, f2, rng, log=None):
    omens = 0
    for rnd in range(1, P['MAX_ROUNDS'] + 1):
        r1 = (rng.choice(f1.atk), rng.choice(f1.dfn))
        r2 = (rng.choice(f2.atk), rng.choice(f2.dfn))
        act1 = f1.policy(f1, f2, r1, r2, rng)
        act2 = f2.policy(f2, f1, r2, r1, rng)
        r1 = apply(f1, act1, r1, rng); r2 = apply(f2, act2, r2, rng)
        omen = len({r1[0][0], r1[1][0], r2[0][0], r2[1][0]}) == 1
        omens += omen
        for me, mine in ((f1, r1), (f2, r2)):
            if mine[0][0] == mine[1][0]:
                me.focus = min(P['FMAX'], me.focus + 1); me.stats['stance'] += 1
        fat = 1 + max(0, rnd - P['FATIGUE_START']) * P['FATIGUE']
        order = [(f1, r1, f2, r2), (f2, r2, f1, r1)]
        if f2.agi > f1.agi or (f2.agi == f1.agi and rnd % 2 == 0): order.reverse()
        new_open = {f1.name: False, f2.name: False}
        for att, ar, dfn, dr in order:
            if att.hp <= 0: continue
            mult, opens = strike_value(ar[0], dr[1], dfn.opened)
            if omen and mult > 0: mult = max(mult, P['HEAD'])
            dmg = att.dmg * mult * fat * rng.uniform(0.9, 1.1)
            dfn.hp -= dmg
            if opens: new_open[dfn.name] = True
            if dfn.hp <= 0: return (att is f1), rnd, omens
        f1.opened, f2.opened = new_open[f1.name], new_open[f2.name]
        f1.focus = min(P['FMAX'], f1.focus + 1); f2.focus = min(P['FMAX'], f2.focus + 1)
    return (f1.hp / f1.maxhp >= f2.hp / f2.maxhp), P['MAX_ROUNDS'], omens

def wr(mk1, mk2, n=6000, seed=1):
    rng = random.Random(seed); w = 0; rs = []; om = 0; st = []
    for _ in range(n):
        a, b = mk1(), mk2()
        r, k, o = fight(a, b, rng); w += r; rs.append(k); om += o
        st.append(a.stats)
    return w / n, mean(rs), om / sum(rs), mean(s['rerolls'] + s['turns'] for s in st)

def gear(atk=None, dfn=None):
    a = list(BASE); d = list(BASE)
    for i, f in (atk or []): a[i] = f
    for i, f in (dfn or []): d[i] = f
    return a, d

if __name__ == '__main__':
    mirror = lambda pol, **kw: (lambda: F('x', pol, **kw))
    print("== Pure mirror, nobody spends ==")
    w, r, om, sp = wr(mirror(never), mirror(never)); print(f"winrate {w:.3f}  rounds {r:.1f}  omen/round {om:.3f}")
    print("\n== Value of decisions (P1 policy vs P2 never) ==")
    for name, pol in (('random spend', random_spend), ('smart', smart)):
        w, r, om, sp = wr(lambda: F('a', pol), mirror(never)); print(f"{name:14s} {w:.3f}  rounds {r:.1f}  spends/fight {sp:.1f}")
    w, r, *_ = wr(lambda: F('a', smart), lambda: F('b', smart)); print(f"smart vs smart {w:.3f} (initiative alternation)")
    print("\n== Gear faces (P1 smart+gear vs P2 smart base) ==")
    items = {
        'Клинок Палача (chest→GOLD head)': gear(atk=[(2, face(HEAD, 'gold'))]),
        'Сапоги Подсечки (chest→legs atk)': gear(atk=[(3, face(LEGS))]),
        'Шлем Стража (chest→head def)': gear(dfn=[(2, face(HEAD))]),
        'Щит-Бастион (legs→WALL def)': gear(dfn=[(4, face(LEGS, 'wall'))]),
        'Бастион + Палач': gear(atk=[(2, face(HEAD, 'gold'))], dfn=[(4, face(LEGS, 'wall'))]),
    }
    for nm, (a, d) in items.items():
        w, r, *_ = wr(lambda: F('a', smart, atk=a, dfn=d), lambda: F('b', smart))
        print(f"{nm:34s} {w:.3f}  rounds {r:.1f}")
    print("\n== Stat edge vs dice: P1 +10% dmg, both smart ==")
    w, *_ = wr(lambda: F('a', smart, dmg=P['DMG'] * 1.1), lambda: F('b', smart)); print(f"+10% dmg {w:.3f}")
    w, *_ = wr(lambda: F('a', smart, dmg=P['DMG'] * 1.25), lambda: F('b', smart)); print(f"+25% dmg {w:.3f}")
