import SwiftUI

extension BattleResultCardView {
    func runAnimationSequence() {
        // Reset per-item reward visibility for staggered reveal
        goldItemVisible = false
        xpItemVisible = false
        ratingItemVisible = false

        // ── 0.0s — Screen flash + card scales in ──
        screenFlashOpacity = config.isVictory ? 0.4 : 0.25
        withAnimation(.easeOut(duration: MotionConstants.fast)) {
            screenFlashOpacity = 0
        }
        withAnimation(MotionConstants.dramatic) {
            showCard = true
        }

        // ── 0.25s — Title SLAMS in (scale 2.5→1.0 with bounce) ──
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.fast) {
            if config.isVictory {
                HapticManager.heavy()
            } else {
                HapticManager.defeat()
            }
            withAnimation(MotionConstants.springBouncy) {
                showTitle = true
            }
        }

        // ── 0.4s — Defeat shake / Victory burst ──
        if config.isVictory {
            DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.normal) {
                showRewardBurst = true
                HapticManager.victory()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.normal) {
                shakeSequence()
                HapticManager.shake()
            }
        }

        // ── 0.5s — Victory stars stagger reveal ──
        // Reveal all slots (earned + missed) so players see what they missed.
        // Earned slots trigger a medium haptic + gold glow; missed slots just fade in.
        if let conditions = config.starConditions, config.isVictory, !conditions.isEmpty {
            for i in 0..<conditions.count {
                let cond = conditions[i]
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.28) {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
                        revealedStars = i + 1
                    }
                    if cond.earned {
                        HapticManager.medium()
                    } else {
                        HapticManager.light()
                    }
                }
            }
        }

        // ── 0.6s — Title glow pulsing begins ──
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.reward) {
            withAnimation(MotionConstants.pulse) {
                titleGlowPulse = true
            }
        }

        // ── 0.8s+ — Rewards header + staggered per-item reveal + counters tick up ──
        // (delayed further if stars are showing — all slots reveal, earned or not)
        let starSlotCount: Int = (config.isVictory ? (config.starConditions?.count ?? 0) : 0)
        let starsDelay: Double = Double(starSlotCount) * 0.28
        let rewardsTime = 0.8 + starsDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + rewardsTime) {
            withAnimation(.easeOut(duration: MotionConstants.fast)) {
                showRewards = true
            }

            // Stagger reveal: Gold @0ms, XP @stagger, Rating @stagger*2 (skipping nil/zero items)
            let stagger = MotionConstants.rewardStaggerInterval
            var slot = 0

            if let gold = config.goldReward, gold > 0 {
                let delay = Double(slot) * stagger; slot += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: MotionConstants.rewardItemFadeIn)) {
                        goldItemVisible = true
                    }
                    HapticManager.light()
                    rollUp(to: gold, binding: $goldDisplay, duration: MotionConstants.tickUpDuration)
                    DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.tickUpDuration) {
                        self.pulseReward(.gold)
                    }
                }
            }

            if let xp = config.xpReward, xp > 0 {
                let delay = Double(slot) * stagger; slot += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: MotionConstants.rewardItemFadeIn)) {
                        xpItemVisible = true
                    }
                    HapticManager.light()
                    rollUp(to: xp, binding: $xpDisplay, duration: MotionConstants.tickUpDuration)
                    DispatchQueue.main.asyncAfter(deadline: .now() + MotionConstants.tickUpDuration) {
                        self.pulseReward(.xp)
                    }
                }
            }

            if let change = config.ratingChange, change != 0 {
                let delay = Double(slot) * stagger; slot += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: MotionConstants.rewardItemFadeIn)) {
                        ratingItemVisible = true
                    }
                    HapticManager.medium()
                    // Integer-by-integer tick for rating
                    let absTarget = abs(change)
                    let stepInterval = min(MotionConstants.ratingTickInterval,
                                           MotionConstants.ratingTickMaxDuration / Double(absTarget))
                    let sign = change < 0 ? -1 : 1
                    ratingDisplay = 0
                    for i in 1...absTarget {
                        DispatchQueue.main.asyncAfter(deadline: .now() + stepInterval * Double(i)) {
                            ratingDisplay = i * sign
                            if i == absTarget {
                                self.pulseReward(.rating)
                            }
                        }
                    }
                }
            }

            // Hero XP counter: roll from xpBefore → xpBefore + xpReward
            if let xpBefore = config.xpBefore {
                let xpAfter = xpBefore + (config.xpReward ?? 0)
                xpHeroDisplay = xpBefore
                rollUp(from: xpBefore, to: xpAfter, binding: $xpHeroDisplay, duration: 1.2)
            }
        }

        // ── Loot section with RARITY-BASED reveal (Audit §7 #11) ──
        // Pushed back to let the staggered reward row + tick-ups complete first.
        let rewardsRevealTotal: Double = {
            var count = 0
            if (config.goldReward ?? 0) > 0 { count += 1 }
            if (config.xpReward ?? 0) > 0 { count += 1 }
            if let r = config.ratingChange, r != 0 { count += 1 }
            let staggerEnd = Double(max(count - 1, 0)) * MotionConstants.rewardStaggerInterval
            // Rating tick may run longest; estimate generously
            let ratingTickEst: Double = {
                guard let r = config.ratingChange, r != 0 else { return MotionConstants.tickUpDuration }
                return min(MotionConstants.ratingTickMaxDuration, Double(abs(r)) * MotionConstants.ratingTickInterval)
            }()
            return staggerEnd + max(MotionConstants.tickUpDuration, ratingTickEst) + MotionConstants.rewardCompletionPulse
        }()
        let lootStartTime = rewardsTime + max(0.6, rewardsRevealTotal)
        if !config.lootItems.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + lootStartTime) {
                withAnimation(.easeOut(duration: MotionConstants.fast)) {
                    showLoot = true
                }
                // Calculate cumulative delay based on rarity tiers
                var cumulativeDelay: Double = 0
                for i in config.lootItems.indices {
                    let tier = config.lootItems[i].rarityTier
                    let itemDelay = cumulativeDelay
                    cumulativeDelay += rarityRevealDelay(tier: tier)

                    DispatchQueue.main.asyncAfter(deadline: .now() + itemDelay) {
                        // Epic/Legendary: anticipation pause (dim + glow)
                        if tier >= 3 {
                            HapticManager.medium()
                        }
                    }

                    // Reveal the item
                    let revealTime = tier >= 3 ? itemDelay + MotionConstants.anticipationDuration : itemDelay
                    DispatchQueue.main.asyncAfter(deadline: .now() + revealTime) {
                        let animation: Animation = tier >= 3
                            ? MotionConstants.springBouncy
                            : tier >= 2 ? MotionConstants.spring : MotionConstants.snappy
                        withAnimation(animation) {
                            _ = revealedLootIndices.insert(i)
                        }
                        // Rarity-scaled haptic
                        switch tier {
                        case 4: HapticManager.legendaryReveal()
                        case 3: HapticManager.heavy()
                        case 2: HapticManager.medium()
                        default: HapticManager.light()
                        }
                    }
                }
            }
        }

        // ── Buttons appear last ──
        let lootTotalDelay = config.lootItems.reduce(0.0) { acc, item in acc + rarityRevealDelay(tier: item.rarityTier) }
        let buttonDelay = config.lootItems.isEmpty ? rewardsTime + max(0.6, rewardsRevealTotal) : lootStartTime + lootTotalDelay + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
            withAnimation(.easeOut(duration: MotionConstants.fast)) {
                showButtons = true
            }
        }
    }

    // MARK: - Shake Effect (defeat)

    func shakeSequence() {
        let offsets: [CGFloat] = [12, -10, 8, -6, 4, -2, 0]
        for (i, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
    }

    // MARK: - Rarity Reveal Timing

    /// Per-item delay based on rarity tier (Audit §3.5)
    func rarityRevealDelay(tier: Int) -> Double {
        switch tier {
        case 0: return 0.12      // common — instant pop
        case 1: return 0.18      // uncommon — quick
        case 2: return 0.28      // rare — noticeable pause
        case 3: return 0.45      // epic — anticipation + reveal
        default: return 0.65     // legendary — full ceremony
        }
    }

    // MARK: - Reward Item Reveal

    enum RewardKind { case gold, xp, rating }

    /// Completion pulse: opacity dip 1.0 → 0.7 → 1.0 (no scale per project rule).
    func pulseReward(_ kind: RewardKind) {
        let half = MotionConstants.rewardCompletionPulse / 2
        withAnimation(.easeOut(duration: half)) {
            switch kind {
            case .gold:   goldPulseOpacity = 0.7
            case .xp:     xpPulseOpacity = 0.7
            case .rating: ratingPulseOpacity = 0.7
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + half) {
            withAnimation(.easeIn(duration: half)) {
                switch kind {
                case .gold:   goldPulseOpacity = 1.0
                case .xp:     xpPulseOpacity = 1.0
                case .rating: ratingPulseOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Counter Roll-Up

    func rollUp(to target: Int, binding: Binding<Int>, duration: Double) {
        rollUp(from: 0, to: target, binding: binding, duration: duration)
    }

    func rollUp(from start: Int, to target: Int, binding: Binding<Int>, duration: Double) {
        guard target != start else { return }
        let steps = 25
        let interval = duration / Double(steps)
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                // Ease-out cubic for satisfying deceleration
                let t = Double(i) / Double(steps)
                let eased = 1.0 - pow(1.0 - t, 3)
                withAnimation(.none) {
                    binding.wrappedValue = start + Int(Double(target - start) * eased)
                }
            }
        }
    }
}
