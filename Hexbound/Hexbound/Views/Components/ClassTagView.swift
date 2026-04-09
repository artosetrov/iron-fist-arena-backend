import SwiftUI

/// Reusable class tag pill — uppercased class name with tinted background.
/// Used in ArenaOpponentCard, CharacterSelectionView, and anywhere a class badge is needed.
///
/// Usage:
/// ```swift
/// ClassTagView(characterClass: .warrior)
/// ClassTagView(characterClass: .mage, text: "CUSTOM LABEL")
/// ```
struct ClassTagView: View {
    let characterClass: CharacterClass
    var text: String?

    private var classColor: Color {
        DarkFantasyTheme.classColor(for: characterClass)
    }

    var body: some View {
        Text(displayText)
            .font(DarkFantasyTheme.body.bold())
            .foregroundStyle(classColor)
            .padding(.horizontal, LayoutConstants.spaceSM)
            .padding(.vertical, LayoutConstants.space2XS)
            .background(
                RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                    .fill(classColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.radiusXS)
                            .stroke(classColor.opacity(0.25), lineWidth: 0.5)
                    )
            )
    }

    private var displayText: String {
        text ?? characterClass.displayName.uppercased()
    }
}
