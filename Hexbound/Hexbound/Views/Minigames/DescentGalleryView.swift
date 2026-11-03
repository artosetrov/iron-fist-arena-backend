#if DEBUG
import SwiftUI

// TEMPORARY (throwaway branch claude/sim-descent, not for main): the Descent run
// screen in fixed states, so CI can screenshot it in a simulator.
// Launch: -DescentGallery -DescentGalleryPage N

struct DescentGalleryView: View {
    let page: Int

    @Environment(AppState.self) private var appState
    @State private var vm: DescentViewModel?

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgAbyss.ignoresSafeArea()
            if let vm, let snapshot = vm.snapshot {
                DescentRunView(vm: vm, snapshot: snapshot, isActive: true, onLeave: {})
            }
        }
        .onAppear {
            guard vm == nil else { return }
            let model = DescentViewModel(appState: appState, cache: nil)
            let fixture = DescentGalleryFixtures.page(page)
            model.snapshot = fixture.snapshot
            model.phase = .playing
            model.banner = fixture.banner
            if let fork = fixture.snapshot.fork {
                model.selectedNodeId = fork.options.first(where: { $0.known })?.id
            }
            vm = model
        }
    }
}

enum DescentGalleryFixtures {
    static let pageCount = 10

    static func page(_ i: Int) -> (snapshot: DescentSnapshot, banner: String?) {
        switch i {
        case 0: return (snap(screen: "combat", current: 4, extra: guardianCombat), nil)
        case 1: return (snap(screen: "combat", depth: 0, depthKey: "ossuary", depthName: "The Ossuary", hero: lowHero, current: 1, extra: ghoulCombat), nil)
        case 2: return (snap(screen: "spoils", current: 1, cleared: true, tale: "It drops, and does not get up.", extra: spoils), "Slain")
        case 3: return (snap(screen: "relic", current: 4, cleared: true, tale: "Warden of the Depths falls, and the gate behind it groans open.", extra: relic), "Guardian slain")
        case 4: return (snap(screen: "camp", current: 2, tale: "A safe hollow. Embers still glow.", extra: camp), nil)
        case 5: return (snap(screen: "fork", current: 2, cleared: true, tale: "Two ways lead on.", extra: fork), nil)
        case 6: return (snap(screen: "event", current: 3, tale: "A stone angel weeps light into a basin.", extra: angel), nil)
        case 7: return (snap(screen: "chest", current: 3, tale: "An iron chest, banded and cold.", extra: chest), nil)
        case 8: return (snap(screen: "merchant", current: 3, tale: "A hooded trader blocks the way.", extra: merchant), nil)
        default: return (snap(screen: "depthCard", current: 0, tale: "The heat rises from below.", extra: ""), nil)
        }
    }

    private static let defaultHero = #"{"hp":412,"maxHp":540,"potions":2,"maxPotions":3,"torches":3,"maxTorches":5,"potionHeal":162,"dmgBonusPct":12,"cursedFights":0}"#
    private static let lowHero = #"{"hp":150,"maxHp":540,"potions":1,"maxPotions":3,"torches":2,"maxTorches":5,"potionHeal":162,"dmgBonusPct":0,"cursedFights":2}"#

    private static func snap(
        screen: String, depth: Int = 2, depthKey: String = "molten", depthName: String = "The Molten Heart",
        hero: String = DescentGalleryFixtures.defaultHero, current: Int, cleared: Bool = false, tale: String? = nil, extra: String
    ) -> DescentSnapshot {
        let taleJSON = tale.map { "\"\($0)\"" } ?? "null"
        let json = """
        {"runId":"gallery","seq":1,"screen":"\(screen)","depth":\(depth),"depthKey":"\(depthKey)","depthName":"\(depthName)",
         "depthBlurb":"Rivers of fire under the old forges.","guardianName":"Warden of the Depths",
         "hero":\(hero),
         "relics":[{"key":"shadowblade","name":"Shadowblade","desc":"Crits cut deeper.","icon":"rush2-relic-shadowblade"},{"key":"lantern","name":"Lantern","desc":"See one room further.","icon":"rush2-relic-lantern"}],
         "bag":{"gold":340,"items":[]},"safe":{"gold":0,"items":[]},"xpEarned":420,
         "stats":{"kills":3,"rooms":4,"chests":1},
         "progress":{"total":5,"current":\(current),"currentCleared":\(cleared)},
         "tale":\(taleJSON),
         "map":{"rows":[],"startNext":[]},"fx":[]\(extra.isEmpty ? "" : ",")
         \(extra)
        }
        """
        do {
            return try JSONDecoder().decode(DescentSnapshot.self, from: Data(json.utf8))
        } catch {
            fatalError("gallery fixture \(screen): \(error)")
        }
    }

    private static let lastRound = #"{"action":"strike","pa":"chest","pg":"chest","ea":"legs","eg":"head","pHit":true,"eBlock":false,"dodged":false,"crit":false,"dealt":310,"healed":0,"eHit":true,"pBlock":false,"taken":38,"crushing":false,"mended":0}"#

    private static let guardianCombat = """
    "combat":{"key":"warden","name":"Warden of the Depths","art":"rush2-boss-warden","kind":"boss","level":30,"hp":1240,"maxHp":1800,
     "traits":[{"key":"enrage","label":"Frenzy below 35% HP","short":"Frenzy below 35%"},{"key":"heavy","label":"Crushing blow every 3rd round","short":"Crush every 3rd"}],
     "windup":true,"enraged":false,"bg":"rush2-bg-molten-arena",
     "verdict":[{"text":"You hit its chest for 310.","tone":"good"},{"text":"It hit your legs for 38.","tone":"bad"}],
     "lastRound":\(lastRound),"canFlee":false}
    """

    private static let ghoulCombat = """
    "combat":{"key":"ghoul","name":"Feral Ghoul","art":"rush2-mob-ghoul","kind":"combat","level":7,"hp":90,"maxHp":420,
     "traits":[{"key":"enrage","label":"Frenzy below 35% HP","short":"Frenzy below 35%"}],
     "windup":false,"enraged":true,"bg":"rush2-bg-ossuary-hall",
     "verdict":[{"text":"You hit its head for 120.","tone":"good"},{"text":"It is frenzied!","tone":"bad"}],
     "lastRound":\(lastRound),"canFlee":true}
    """

    private static let spoils = #""spoils":{"bg":"rush2-bg-molten-hall","loot":[{"kind":"gold","amount":180},{"kind":"xp","amount":95},{"kind":"potion","amount":1}]}"#

    private static let relic = #""relicChoice":{"loot":[{"kind":"gold","amount":420},{"kind":"xp","amount":260}],"choices":[{"key":"bloodstone","name":"Bloodstone","desc":"Heal 5% on every kill.","icon":"rush2-relic-bloodstone"},{"key":"ironheart","name":"Iron Heart","desc":"+60 max HP.","icon":"rush2-relic-ironheart"},{"key":"eagleeye","name":"Eagle Eye","desc":"+8% crit chance.","icon":"rush2-relic-eagleeye"}]}"#

    private static let camp = #""camp":{"done":false,"choice":null,"canStash":true,"stashGold":340,"stashItems":0}"#

    private static let fork = #""fork":{"lead":"Two ways lead on.","isBossGate":false,"options":[{"id":"n31","lane":0,"side":"Left","known":true,"type":"combat","typeName":"Monster","cue":"Claws scrape on stone.","fled":false,"revealed":false},{"id":"n32","lane":2,"side":"Right","known":false,"type":null,"typeName":null,"cue":"Only darkness, and a cold draft.","fled":false,"revealed":false}]}"#

    private static let angel = #""event":{"id":"angel","scene":"rush2-ev-angel","text":"A stone angel weeps light into a basin.","done":false,"resultText":null,"loot":[],"then":null,"choices":[{"i":0,"label":"Pray for strength","hint":"{++15% damage+} for the rest of the run.","icon":"rush2-relic-shadowblade","disabledReason":null},{"i":1,"label":"Pray for vigor","hint":"{++150 max HP+} and heal 150.","icon":"rush2-icon-potion","disabledReason":null}],"runes":null}"#

    private static let chest = #""chest":{"tier":"iron","name":"Iron chest","inspected":false,"opened":false,"loot":[]}"#

    private static let merchant = #""merchant":{"wares":[{"i":0,"kind":"potion","name":"Health potion","desc":"Heals 162.","icon":"rush2-icon-potion","price":100,"sold":false,"available":true},{"i":1,"kind":"torch","name":"Torch","desc":"Light a dark passage.","icon":"rush2-icon-torch","price":45,"sold":false,"available":true},{"i":2,"kind":"relic","name":"Bloodstone","desc":"Heal 5% on every kill.","icon":"rush2-relic-bloodstone","price":320,"sold":false,"available":true},{"i":3,"kind":"relic","name":"Iron Heart","desc":"+60 max HP.","icon":"rush2-relic-ironheart","price":320,"sold":false,"available":false}]}"#
}
#endif
