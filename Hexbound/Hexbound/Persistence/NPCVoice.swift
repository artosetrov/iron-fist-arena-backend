import Foundation

/// Voice-over for NPC speech (tutorial guide, merchant, arena master, Finch,
/// Lady Fortuna, contextual hints…).
///
/// Lines are pre-generated and shipped in the bundle under `NPC/` (a folder
/// reference). `NPC/npc_voice_manifest.json` maps a *normalized* line text to
/// the audio file name, so any view that already shows NPC text can voice it
/// with `NPCVoice.shared.speak(text)` — no per-screen line ids to keep in sync.
///
/// Normalization = lowercase ASCII letters and digits only. It must match
/// `scripts/npc_voice/build_catalog.py`, which produced the manifest.
/// A line with no recording (new copy, server text) is simply silent.
///
/// Playback goes through `AudioManager.playVoice`, so BGM is ducked while the
/// NPC talks and the existing mute switch applies.
@MainActor
final class NPCVoice {
    static let shared = NPCVoice()

    private let settings = SettingsManager.shared
    private lazy var manifest: [String: String] = Self.loadManifest()
    /// Key of the line currently voiced — lets `stop(_:)` ignore a stale
    /// onDisappear from the widget that is being replaced.
    private var currentKey: String?
    /// Lines that should be voiced once per app launch (persistent banners).
    private var spokenThisLaunch: Set<String> = []

    private init() {}

    // MARK: - Public API

    /// Voice `text` if a recording exists. Re-calling with the line that is
    /// already playing is a no-op; a different line interrupts the current one.
    func speak(_ text: String) {
        guard settings.npcVoiceEnabled, !settings.isMuted else { return }
        let key = Self.normalize(text)
        guard !key.isEmpty, let file = manifest[key] else { return }
        if currentKey == key, AudioManager.shared.isVoicePlaying { return }
        currentKey = key
        AudioManager.shared.playVoice("NPC/\(file)") { [weak self] in
            if self?.currentKey == key { self?.currentKey = nil }
        }
    }

    /// Voice `text` only the first time it appears this launch — for banners
    /// that stay on screen and re-render (e.g. the tutorial quest banner).
    func speakOnce(_ text: String) {
        let key = Self.normalize(text)
        guard !spokenThisLaunch.contains(key) else { return }
        spokenThisLaunch.insert(key)
        speak(text)
    }

    /// Stop the NPC line — but only if it is `text` (or any line when nil).
    /// Widgets call this from `onDisappear`; during a crossfade the old
    /// widget disappears after the new one started talking, and must not
    /// cut it off.
    func stop(_ text: String? = nil) {
        guard let current = currentKey else { return }
        if let text, Self.normalize(text) != current { return }
        currentKey = nil
        AudioManager.shared.stopVoice(fadeOut: true)
    }

    /// True when a recording exists for `text` (used by previews / QA).
    func hasRecording(for text: String) -> Bool {
        manifest[Self.normalize(text)] != nil
    }

    // MARK: - Internals

    nonisolated static func normalize(_ text: String) -> String {
        // Built scalar by scalar rather than filter().map(Character.init):
        // filtering a UnicodeScalarView yields [Unicode.Scalar], and the
        // unapplied `Character.init` over that array does not resolve — the
        // compiler gives up on the surrounding String(...) and suggests
        // String(describing:), which would have stringified the array.
        var kept = String.UnicodeScalarView()
        for scalar in text.lowercased().unicodeScalars
        where scalar.isASCII && CharacterSet.alphanumerics.contains(scalar) {
            kept.append(scalar)
        }
        return String(kept)
    }

    private static func loadManifest() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "npc_voice_manifest", withExtension: "json", subdirectory: "NPC"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode([String: String].self, from: data) else {
            #if DEBUG
            print("[NPCVoice] manifest missing — NPC lines will be silent")
            #endif
            return [:]
        }
        return map
    }
}
