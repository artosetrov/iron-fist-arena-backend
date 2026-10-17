import SwiftUI

/// Narration markup used by the Descent server (`descent/content.ts`):
/// `**x**` highlighted (gold) · `{+x+}` good (green) · `{-x-}` bad (red).
enum DescentText {
    enum Style { case plain, gold, good, bad }

    struct Run: Equatable {
        let text: String
        let style: Style
    }

    private static let markers: [(open: String, close: String, style: Style)] = [
        ("**", "**", .gold), ("{+", "+}", .good), ("{-", "-}", .bad),
    ]

    static func runs(_ source: String) -> [Run] {
        var out: [Run] = []
        var rest = source[...]
        while !rest.isEmpty {
            var hit: (open: Range<Substring.Index>, close: String, style: Style)?
            for marker in markers {
                guard let range = rest.range(of: marker.open) else { continue }
                if let current = hit, current.open.lowerBound <= range.lowerBound { continue }
                hit = (range, marker.close, marker.style)
            }
            guard let found = hit,
                  let end = rest[found.open.upperBound...].range(of: found.close) else {
                out.append(Run(text: String(rest), style: .plain))
                break
            }
            if found.open.lowerBound > rest.startIndex {
                out.append(Run(text: String(rest[..<found.open.lowerBound]), style: .plain))
            }
            out.append(Run(text: String(rest[found.open.upperBound..<end.lowerBound]), style: found.style))
            rest = rest[end.upperBound...]
        }
        return out
    }

    static func attributed(_ source: String, base: Color = DarkFantasyTheme.textPrimary) -> AttributedString {
        var result = AttributedString()
        for run in runs(source) {
            var piece = AttributedString(run.text)
            switch run.style {
            case .plain:
                piece.foregroundColor = base
            case .gold:
                piece.foregroundColor = DarkFantasyTheme.goldBright
                piece.inlinePresentationIntent = .stronglyEmphasized
            case .good:
                piece.foregroundColor = DarkFantasyTheme.textSuccess
            case .bad:
                piece.foregroundColor = DarkFantasyTheme.textDanger
            }
            result.append(piece)
        }
        return result
    }

    /// Markup removed — for VoiceOver labels.
    static func plain(_ source: String) -> String {
        runs(source).map(\.text).joined()
    }

    static func roman(_ n: Int) -> String {
        let table = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        return n >= 0 && n < table.count ? table[n] : "\(n)"
    }
}

/// A narration line in the Descent's storybook voice.
struct DescentTale: View {
    let text: String
    var base: Color = DarkFantasyTheme.textPrimary

    var body: some View {
        Text(DescentText.attributed(text, base: base))
            .font(DarkFantasyTheme.tale)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(DescentText.plain(text))
    }
}
