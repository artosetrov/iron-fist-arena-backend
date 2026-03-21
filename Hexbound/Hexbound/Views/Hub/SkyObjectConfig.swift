import SwiftUI

// MARK: - Sky Object Data Model (moon, clouds — parallax layers on hub map)

enum SkyLayer: String, CaseIterable {
    case moon       // behind everything, slowest parallax
    case backCloud  // behind terrain, medium parallax
    case frontCloud // over terrain + buildings, fastest parallax
}

struct SkyObject: Identifiable {
    let id: String
    let imageName: String
    let layer: SkyLayer
    var relativeX: CGFloat       // 0.0…1.0 position on terrain
    var relativeY: CGFloat       // 0.0…1.0 position on terrain
    var relativeSize: CGFloat    // size relative to terrain height
    let driftSpeed: Double       // seconds per drift cycle (0 = no drift)
    let driftRange: CGFloat      // drift amplitude in points
    let opacity: Double          // 0.0…1.0
}

// MARK: - Default Sky Objects (hardcoded fallback)

let defaultSkyObjects: [SkyObject] = [
    // Moon
    SkyObject(
        id: "moon",
        imageName: "moon",
        layer: .moon,
        relativeX: 0.35,
        relativeY: 0.12,
        relativeSize: 0.22,
        driftSpeed: 0,
        driftRange: 0,
        opacity: 1.0
    ),

    // Back clouds (behind terrain, over moon)
    SkyObject(
        id: "cloud-back-1",
        imageName: "cloud-1",
        layer: .backCloud,
        relativeX: 0.12,
        relativeY: 0.06,
        relativeSize: 0.26,
        driftSpeed: 80,
        driftRange: 30,
        opacity: 0.55
    ),
    SkyObject(
        id: "cloud-back-2",
        imageName: "cloud-2",
        layer: .backCloud,
        relativeX: 0.35,
        relativeY: 0.12,
        relativeSize: 0.22,
        driftSpeed: 100,
        driftRange: 25,
        opacity: 0.45
    ),
    SkyObject(
        id: "cloud-back-3",
        imageName: "cloud-1",
        layer: .backCloud,
        relativeX: 0.58,
        relativeY: 0.04,
        relativeSize: 0.24,
        driftSpeed: 90,
        driftRange: 35,
        opacity: 0.40
    ),
    SkyObject(
        id: "cloud-back-4",
        imageName: "cloud-2",
        layer: .backCloud,
        relativeX: 0.80,
        relativeY: 0.09,
        relativeSize: 0.20,
        driftSpeed: 95,
        driftRange: 20,
        opacity: 0.35
    ),
    SkyObject(
        id: "cloud-back-5",
        imageName: "cloud-1",
        layer: .backCloud,
        relativeX: 0.03,
        relativeY: 0.18,
        relativeSize: 0.14,
        driftSpeed: 110,
        driftRange: 20,
        opacity: 0.25
    ),
    SkyObject(
        id: "cloud-back-6",
        imageName: "cloud-2",
        layer: .backCloud,
        relativeX: 0.48,
        relativeY: 0.20,
        relativeSize: 0.17,
        driftSpeed: 105,
        driftRange: 25,
        opacity: 0.30
    ),

    // Front clouds (over terrain + buildings)
    SkyObject(
        id: "cloud-front-1",
        imageName: "cloud-1",
        layer: .frontCloud,
        relativeX: 0.08,
        relativeY: 0.04,
        relativeSize: 0.36,
        driftSpeed: 65,
        driftRange: 50,
        opacity: 0.22
    ),
    SkyObject(
        id: "cloud-front-2",
        imageName: "cloud-2",
        layer: .frontCloud,
        relativeX: 0.32,
        relativeY: 0.14,
        relativeSize: 0.32,
        driftSpeed: 80,
        driftRange: 40,
        opacity: 0.18
    ),
    SkyObject(
        id: "cloud-front-3",
        imageName: "cloud-1",
        layer: .frontCloud,
        relativeX: 0.55,
        relativeY: 0.07,
        relativeSize: 0.34,
        driftSpeed: 70,
        driftRange: 45,
        opacity: 0.20
    ),
    SkyObject(
        id: "cloud-front-4",
        imageName: "cloud-2",
        layer: .frontCloud,
        relativeX: 0.82,
        relativeY: 0.18,
        relativeSize: 0.29,
        driftSpeed: 90,
        driftRange: 35,
        opacity: 0.16
    ),
    SkyObject(
        id: "cloud-front-5",
        imageName: "cloud-1",
        layer: .frontCloud,
        relativeX: 0.20,
        relativeY: 0.32,
        relativeSize: 0.27,
        driftSpeed: 100,
        driftRange: 30,
        opacity: 0.14
    ),
    SkyObject(
        id: "cloud-front-6",
        imageName: "cloud-2",
        layer: .frontCloud,
        relativeX: 0.68,
        relativeY: 0.38,
        relativeSize: 0.24,
        driftSpeed: 95,
        driftRange: 25,
        opacity: 0.12
    ),
]

// MARK: - Parallax factors per layer

func parallaxFactor(for layer: SkyLayer) -> CGFloat {
    switch layer {
    case .moon: return 0.85       // moves at ~15% speed
    case .backCloud: return 0.65  // moves at ~35% speed
    case .frontCloud: return 0.25 // moves at ~75% speed
    }
}

// MARK: - Resolved sky objects (with server overrides)

@MainActor
func resolvedSkyObjects(from cache: GameDataCache) -> [SkyObject] {
    let overrides = cache.skyLayout
    guard !overrides.isEmpty else { return defaultSkyObjects }

    return defaultSkyObjects.map { obj in
        var o = obj
        if let ov = overrides[obj.id] {
            o.relativeX = ov.x
            o.relativeY = ov.y
            if let size = ov.size { o.relativeSize = size }
        }
        return o
    }
}
