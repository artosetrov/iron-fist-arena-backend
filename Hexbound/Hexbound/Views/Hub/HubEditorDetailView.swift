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

    // Image native aspect ratio (4096×1738)
    private let imageAspect: CGFloat = 4096.0 / 1738.0

    /// Buildings with current server overrides applied
    private var buildings: [CityBuilding] {
        resolvedCityBuildings(from: cache)
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
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
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
                Button("Reset All") {
                    withAnimation {
                        dragOffsets.removeAll()
                        sizeOverrides.removeAll()
                    }
                }
                .font(DarkFantasyTheme.body(size: 14))
                .foregroundStyle(DarkFantasyTheme.danger)
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
                context.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 0.5)
                x += step
            }
            var y: CGFloat = 0
            while y <= 1.0 {
                let py = y * size.height
                var path = Path()
                path.move(to: CGPoint(x: 0, y: py))
                path.addLine(to: CGPoint(x: size.width, y: py))
                context.stroke(path, with: .color(.white.opacity(0.08)), lineWidth: 0.5)
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
            // Selected building info
            if let sel = selectedBuilding,
               let building = buildings.first(where: { $0.id == sel }) {
                let offset = dragOffsets[building.id] ?? .zero
                let finalX = building.relativeX + offset.width / terrainSize.width
                let finalY = building.relativeY + offset.height / terrainSize.height
                let currentSize = sizeOverrides[building.id] ?? building.relativeSize

                HStack {
                    Text(building.label)
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
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
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

        // 1. Update local cache FIRST (instant effect on hub)
        cache.cacheHubLayout(overrides)
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
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(isSelected ? Color.red.opacity(0.8) : Color.black.opacity(0.7))
                .cornerRadius(4)

            if UIImage(named: building.imageName) != nil {
                Image(building.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: buildingHeight)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.red.opacity(0.4) : Color.orange.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.red : Color.orange, lineWidth: 2)
                    )
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: building.fallbackIcon)
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                            Text(building.label)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    )
                    .frame(width: buildingHeight * 0.7, height: buildingHeight)
            }
        }
        .overlay(
            isSelected ?
                RoundedRectangle(cornerRadius: 6)
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

#endif
