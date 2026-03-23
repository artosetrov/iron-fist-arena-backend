import SwiftUI

#if DEBUG

// MARK: - Hub Editor Detail View (admin tool: drag buildings, save to server)

struct HubEditorDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(GameDataCache.self) private var cache
    @State private var dragOffsets: [String: CGSize] = [:]
    @State private var sizeOverrides: [String: CGFloat] = [:]
    @State private var selectedBuilding: String? = nil
    @State private var toastMessage: String? = nil
    @State private var isSaving = false
    @State private var showSkyObjects = true // toggle sky objects visibility in editor

    // Image native aspect ratio (4096×1738)
    private let imageAspect: CGFloat = 4096.0 / 1738.0

    /// Buildings with current server overrides applied
    private var buildings: [CityBuilding] {
        resolvedCityBuildings(from: cache)
    }

    /// Sky objects with current overrides applied
    private var skyObjects: [SkyObject] {
        resolvedSkyObjects(from: cache)
    }

    var body: some View {
        ZStack {
            DarkFantasyTheme.bgPrimary.ignoresSafeArea()

            GeometryReader { outerGeo in
                let viewHeight = outerGeo.size.height - 120
                let terrainWidth = viewHeight * imageAspect
                let terrainSize = CGSize(width: terrainWidth, height: viewHeight)

                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            Image("bg-hub")
                                .resizable()
                                .frame(width: terrainWidth, height: viewHeight)

                            gridOverlay(terrainSize: terrainSize)

                            ForEach(buildings) { building in
                                DraggableEditorBuilding(
                                    building: building,
                                    terrainSize: terrainSize,
                                    dragOffset: dragOffsets[building.id] ?? .zero,
                                    sizeOverride: sizeOverrides[building.id],
                                    isSelected: selectedBuilding == building.id,
                                    onSelect: { selectedBuilding = building.id },
                                    onDragEnd: { newOffset in
                                        dragOffsets[building.id] = newOffset
                                    }
                                )
                            }

                            // Sky objects (moon + clouds) — draggable + resizable
                            if showSkyObjects {
                                ForEach(skyObjects) { obj in
                                    DraggableEditorSkyObject(
                                        object: obj,
                                        terrainSize: terrainSize,
                                        dragOffset: dragOffsets[obj.id] ?? .zero,
                                        sizeOverride: sizeOverrides[obj.id],
                                        isSelected: selectedBuilding == obj.id,
                                        onSelect: { selectedBuilding = obj.id },
                                        onDragEnd: { newOffset in
                                            dragOffsets[obj.id] = newOffset
                                        }
                                    )
                                }
                            }
                        }
                        .frame(width: terrainWidth, height: viewHeight)
                    }
                    .defaultScrollAnchor(.center)

                    controlPanel(terrainSize: terrainSize)
                }
            }

            // Toast
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(DarkFantasyTheme.body(size: 14))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                        .padding(.horizontal, LayoutConstants.spaceMD)
                        .padding(.vertical, LayoutConstants.spaceMS)
                        .background(DarkFantasyTheme.success.opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.bottom, 140)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HubLogoButton()
            }
            ToolbarItem(placement: .principal) {
                Text("HUB EDITOR")
                    .font(DarkFantasyTheme.title(size: LayoutConstants.textSection))
                    .foregroundStyle(DarkFantasyTheme.goldBright)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: LayoutConstants.spaceMS) {
                    Button(showSkyObjects ? "☁️ On" : "☁️ Off") {
                        withAnimation { showSkyObjects.toggle() }
                    }
                    .font(DarkFantasyTheme.body(size: 12))
                    .foregroundStyle(showSkyObjects ? DarkFantasyTheme.gold : DarkFantasyTheme.textSecondary)
                    .buttonStyle(.scalePress)

                    Button("Reset All") {
                        withAnimation {
                            dragOffsets.removeAll()
                            sizeOverrides.removeAll()
                        }
                    }
                    .font(DarkFantasyTheme.body(size: 14))
                    .foregroundStyle(DarkFantasyTheme.danger)
                    .buttonStyle(.scalePress)
                }
            }
        }
    }

    // MARK: - Grid Overlay

    @ViewBuilder
    private func gridOverlay(terrainSize: CGSize) -> some View {
        Canvas { context, size in
            let step: CGFloat = 0.1
            var x: CGFloat = 0
            while x <= 1.0 {
                let px = x * size.width
                var path = Path()
                path.move(to: CGPoint(x: px, y: 0))
                path.addLine(to: CGPoint(x: px, y: size.height))
                context.stroke(path, with: .color(DarkFantasyTheme.textPrimary.opacity(0.08)), lineWidth: 0.5)
                x += step
            }
            var y: CGFloat = 0
            while y <= 1.0 {
                let py = y * size.height
                var path = Path()
                path.move(to: CGPoint(x: 0, y: py))
                path.addLine(to: CGPoint(x: size.width, y: py))
                context.stroke(path, with: .color(DarkFantasyTheme.textPrimary.opacity(0.08)), lineWidth: 0.5)
                y += step
            }
        }
        .frame(width: terrainSize.width, height: terrainSize.height)
        .allowsHitTesting(false)
    }

    // MARK: - Control Panel

    @ViewBuilder
    private func controlPanel(terrainSize: CGSize) -> some View {
        VStack(spacing: LayoutConstants.spaceSM) {
            // Selected object info (building or sky object)
            if let sel = selectedBuilding,
               let (label, baseX, baseY, baseSize) = selectedObjectInfo(sel) {
                let offset = dragOffsets[sel] ?? .zero
                let finalX = baseX + offset.width / terrainSize.width
                let finalY = baseY + offset.height / terrainSize.height
                let currentSize = sizeOverrides[sel] ?? baseSize

                HStack {
                    Text(label)
                        .font(DarkFantasyTheme.section(size: 14))
                        .foregroundStyle(DarkFantasyTheme.gold)
                    Spacer()
                    Text("(\(String(format: "%.2f", finalX)), \(String(format: "%.2f", finalY))) S: \(String(format: "%.2f", currentSize))")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(DarkFantasyTheme.textPrimary)
                }

                // Size controls
                HStack(spacing: LayoutConstants.spaceSM) {
                    Button {
                        sizeOverrides[sel] = max(0.05, currentSize - 0.02)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    .buttonStyle(.scalePress)

                    Slider(
                        value: Binding(
                            get: { currentSize },
                            set: { sizeOverrides[sel] = $0 }
                        ),
                        in: 0.05...0.60,
                        step: 0.01
                    )
                    .tint(DarkFantasyTheme.gold)

                    Button {
                        sizeOverrides[sel] = min(0.60, currentSize + 0.02)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(DarkFantasyTheme.textSecondary)
                    }
                    .buttonStyle(.scalePress)
                }
            } else {
                Text("Tap a building to select, drag to move")
                    .font(DarkFantasyTheme.body(size: 13))
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
            }

            // Save to server (admin endpoint)
            Button {
                Task { await saveToServer(terrainSize: terrainSize) }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .textPrimary))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "icloud.and.arrow.up.fill")
                    }
                    Text("Save to Server")
                }
            }
            .buttonStyle(.primary)
            .disabled(isSaving)

            // Copy to clipboard (for hardcoding)
            Button {
                exportCoordinates(terrainSize: terrainSize)
            } label: {
                HStack {
                    Image(systemName: "doc.on.clipboard")
                    Text("Copy to Clipboard")
                }
            }
            .buttonStyle(.secondary)
        }
        .padding(.horizontal, LayoutConstants.screenPadding)
        .padding(.vertical, LayoutConstants.spaceSM)
        .background(DarkFantasyTheme.bgSecondary)
    }

    // MARK: - Save to Server

    private func saveToServer(terrainSize: CGSize) async {
        isSaving = true
        defer { isSaving = false }

        // Build final overrides (position + size)
        var overrides: [String: GameDataCache.BuildingOverride] = [:]
        var layout: [String: [String: CGFloat]] = [:]
        for building in buildings {
            let offset = dragOffsets[building.id] ?? .zero
            let finalX = building.relativeX + offset.width / terrainSize.width
            let finalY = building.relativeY + offset.height / terrainSize.height
            let finalSize = sizeOverrides[building.id] ?? building.relativeSize
            overrides[building.id] = GameDataCache.BuildingOverride(x: finalX, y: finalY, size: finalSize)
            layout[building.id] = ["x": finalX, "y": finalY, "size": finalSize]
        }

        // Build sky overrides
        var skyOverrides: [String: GameDataCache.BuildingOverride] = [:]
        for obj in skyObjects {
            let offset = dragOffsets[obj.id] ?? .zero
            let finalX = obj.relativeX + offset.width / terrainSize.width
            let finalY = obj.relativeY + offset.height / terrainSize.height
            let finalSize = sizeOverrides[obj.id] ?? obj.relativeSize
            skyOverrides[obj.id] = GameDataCache.BuildingOverride(x: finalX, y: finalY, size: finalSize)
        }

        // 1. Update local cache FIRST (instant effect on hub)
        cache.cacheHubLayout(overrides)
        cache.cacheSkyLayout(skyOverrides)
        dragOffsets.removeAll()
        sizeOverrides.removeAll()

        // 2. Try to persist to server (so all users get it)
        do {
            let _ = try await APIClient.shared.postRaw(
                APIEndpoints.adminHubLayout,
                body: ["layout": layout]
            )
            showToast("Saved to server!")
        } catch {
            // Cache is already updated — hub works, but other users won't see it
            showToast("Saved locally (server sync failed)")
            print("[HubEditor] API error: \(error.localizedDescription)")
        }
    }

    // MARK: - Export to Clipboard

    private func exportCoordinates(terrainSize: CGSize) {
        var output = "\n// MARK: - Updated Building Positions\n\n"
        for building in buildings {
            let offset = dragOffsets[building.id] ?? .zero
            let finalX = building.relativeX + offset.width / terrainSize.width
            let finalY = building.relativeY + offset.height / terrainSize.height
            let finalSize = sizeOverrides[building.id] ?? building.relativeSize
            output += "    // \(building.label)\n"
            output += "    relativeX: \(String(format: "%.2f", finalX)),\n"
            output += "    relativeY: \(String(format: "%.2f", finalY)),\n"
            output += "    relativeSize: \(String(format: "%.2f", finalSize)),\n\n"
        }
        print(output)
        UIPasteboard.general.string = output
        showToast("Copied to clipboard")
    }

    /// Returns (label, baseX, baseY, baseSize) for any selected object (building or sky)
    private func selectedObjectInfo(_ id: String) -> (String, CGFloat, CGFloat, CGFloat)? {
        if let b = buildings.first(where: { $0.id == id }) {
            return (b.label, b.relativeX, b.relativeY, b.relativeSize)
        }
        if let s = skyObjects.first(where: { $0.id == id }) {
            return (s.id.uppercased(), s.relativeX, s.relativeY, s.relativeSize)
        }
        return nil
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}

// MARK: - Draggable Editor Building

struct DraggableEditorBuilding: View {
    let building: CityBuilding
    let terrainSize: CGSize
    let dragOffset: CGSize
    var sizeOverride: CGFloat? = nil
    let isSelected: Bool
    let onSelect: () -> Void
    let onDragEnd: (CGSize) -> Void

    @State private var currentDrag: CGSize = .zero

    private var effectiveSize: CGFloat {
        sizeOverride ?? building.relativeSize
    }

    private var buildingHeight: CGFloat {
        terrainSize.height * effectiveSize
    }

    private var finalX: CGFloat {
        building.relativeX + (dragOffset.width + currentDrag.width) / terrainSize.width
    }
    private var finalY: CGFloat {
        building.relativeY + (dragOffset.height + currentDrag.height) / terrainSize.height
    }

    var body: some View {
        let baseX = terrainSize.width * building.relativeX
        let baseY = terrainSize.height * building.relativeY

        VStack(spacing: 2) {
            Text("\(building.id) (\(String(format: "%.2f", finalX)), \(String(format: "%.2f", finalY)))")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.horizontal, LayoutConstants.spaceXS)
                .padding(.vertical, LayoutConstants.space2XS)
                .background(isSelected ? Color.red.opacity(0.8) : DarkFantasyTheme.bgAbyss.opacity(0.7))
                .cornerRadius(LayoutConstants.radiusXS)

            if UIImage(named: building.imageName) != nil {
                Image(building.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: buildingHeight)
            } else {
                RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                    .fill(isSelected ? Color.red.opacity(0.4) : Color.orange.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                            .stroke(isSelected ? Color.red : Color.orange, lineWidth: 2)
                    )
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: building.fallbackIcon)
                                .font(.system(size: 24))
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                            Text(building.label)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DarkFantasyTheme.textPrimary)
                        }
                    )
                    .frame(width: buildingHeight * 0.7, height: buildingHeight)
            }
        }
        .overlay(
            isSelected ?
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(Color.red, lineWidth: 2)
                    .padding(-4)
            : nil
        )
        .position(
            x: baseX + dragOffset.width + currentDrag.width,
            y: baseY + dragOffset.height + currentDrag.height
        )
        .simultaneousGesture(
            TapGesture().onEnded { onSelect() }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    currentDrag = value.translation
                    onSelect()
                }
                .onEnded { value in
                    let newOffset = CGSize(
                        width: dragOffset.width + value.translation.width,
                        height: dragOffset.height + value.translation.height
                    )
                    currentDrag = .zero
                    onDragEnd(newOffset)
                }
        )
    }
}

// MARK: - Draggable Editor Sky Object

struct DraggableEditorSkyObject: View {
    let object: SkyObject
    let terrainSize: CGSize
    let dragOffset: CGSize
    var sizeOverride: CGFloat? = nil
    let isSelected: Bool
    let onSelect: () -> Void
    let onDragEnd: (CGSize) -> Void

    @State private var currentDrag: CGSize = .zero

    private var effectiveSize: CGFloat {
        sizeOverride ?? object.relativeSize
    }

    private var objectHeight: CGFloat {
        terrainSize.height * effectiveSize
    }

    private var finalX: CGFloat {
        object.relativeX + (dragOffset.width + currentDrag.width) / terrainSize.width
    }
    private var finalY: CGFloat {
        object.relativeY + (dragOffset.height + currentDrag.height) / terrainSize.height
    }

    private var layerColor: Color {
        switch object.layer {
        case .moon: return .yellow
        case .backCloud: return .cyan
        case .frontCloud: return .purple
        }
    }

    var body: some View {
        let baseX = terrainSize.width * object.relativeX
        let baseY = terrainSize.height * object.relativeY

        VStack(spacing: LayoutConstants.space2XS) {
            Text("\(object.id) (\(String(format: "%.2f", finalX)), \(String(format: "%.2f", finalY)))")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(DarkFantasyTheme.textPrimary)
                .padding(.horizontal, LayoutConstants.space2XS)
                .padding(.vertical, 1)
                .background(isSelected ? layerColor.opacity(0.9) : layerColor.opacity(0.5))
                .cornerRadius(LayoutConstants.radiusXS)

            Image(object.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: objectHeight)
                .opacity(object.layer == .moon ? 1.0 : object.opacity + 0.3)
        }
        .overlay(
            isSelected ?
                RoundedRectangle(cornerRadius: LayoutConstants.radiusSM)
                    .stroke(layerColor, lineWidth: 2)
                    .padding(-4)
            : nil
        )
        .position(
            x: baseX + dragOffset.width + currentDrag.width,
            y: baseY + dragOffset.height + currentDrag.height
        )
        .simultaneousGesture(
            TapGesture().onEnded { onSelect() }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    currentDrag = value.translation
                    onSelect()
                }
                .onEnded { value in
                    let newOffset = CGSize(
                        width: dragOffset.width + value.translation.width,
                        height: dragOffset.height + value.translation.height
                    )
                    currentDrag = .zero
                    onDragEnd(newOffset)
                }
        )
    }
}

#endif
