import AppKit
import SwiftUI

extension Color {
    static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

enum AppTheme {
    /// Softened graphite for control labels, so filled buttons stay low-contrast.
    static let buttonText = Color.adaptive(
        light: NSColor(srgbRed: 0.24, green: 0.24, blue: 0.25, alpha: 1),
        dark: NSColor(srgbRed: 0.93, green: 0.93, blue: 0.94, alpha: 1)
    )
    /// Lighter graphite for icons, labels, borders and translucent selections.
    static let accentText = Color.adaptive(
        light: NSColor(srgbRed: 0.29, green: 0.29, blue: 0.29, alpha: 1),
        dark: NSColor(srgbRed: 0.74, green: 0.74, blue: 0.74, alpha: 1)
    )
    /// App-mark palette: light-gray tile with a graphite glyph, complementing the white Dock icon.
    static let markTop = Color(red: 0.972, green: 0.972, blue: 0.978)
    static let markBottom = Color(red: 0.884, green: 0.884, blue: 0.896)
    static let markGlyph = Color(red: 0.30, green: 0.30, blue: 0.31)
    static let success = Color(red: 0.14, green: 0.66, blue: 0.36)
    static let warning = Color(red: 0.94, green: 0.58, blue: 0.12)
    static let danger = Color(red: 0.91, green: 0.25, blue: 0.23)
}

/// Compact version of the Dock icon: light-gray squircle, graphite printer and a CMYK paper strip.
struct AppMark: View {
    var size: CGFloat = 40

    private var cornerRadius: CGFloat { size * 0.28 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.markTop, AppTheme.markBottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.white.opacity(0)],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            VStack(spacing: size * 0.07) {
                Image(systemName: "printer.fill")
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.markGlyph)
                    .shadow(color: Color.white.opacity(0.55), radius: size * 0.02, y: size * 0.012)

                RoundedRectangle(cornerRadius: size * 0.025, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.22, green: 0.80, blue: 0.98),
                                Color(red: 1.00, green: 0.34, blue: 0.63),
                                Color(red: 1.00, green: 0.82, blue: 0.24)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 0.42, height: size * 0.055)
            }
            .offset(y: size * 0.015)
        }
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
        }
    }
}

struct CardSurface: ViewModifier {
    var cornerRadius: CGFloat = 18
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.055),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.07),
                radius: 22,
                y: 9
            )
    }
}

extension View {
    func cardSurface(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius))
    }

    func controlChrome(cornerRadius: CGFloat = 9) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.52))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
    }
}

struct SettingLabel: View {
    let title: String
    var symbol: String?

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9.5, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.2)
        }
        .foregroundStyle(.secondary)
    }
}

struct FileKindBadge: View {
    let kind: PrintFileKind
    var size: CGFloat = 32

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            .fill(kind.tint.opacity(0.14))
            .overlay(
                Image(systemName: kind.symbolName)
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(kind.tint)
            )
            .frame(width: size, height: size)
    }
}

struct MenuControlLabel: View {
    let symbol: String?
    let text: String
    var isWarning = false

    var body: some View {
        HStack(spacing: 7) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isWarning ? AppTheme.warning : .secondary)
            }

            Text(text)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(isWarning ? AppTheme.warning : .primary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer(minLength: 4)

            Image(systemName: "chevron.down")
                .font(.system(size: 8.5, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .controlChrome()
        .contentShape(Rectangle())
    }
}

struct SegmentedControl<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String
    let symbol: (Option) -> String

    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                Button {
                    withAnimation(.easeOut(duration: 0.16)) {
                        selection = option
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: symbol(option))
                            .font(.system(size: 9.5, weight: .semibold))
                        Text(title(option))
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundStyle(selection == option ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                    .background {
                        if selection == option {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(AppTheme.accentText.opacity(0.16))
                                .matchedGeometryEffect(id: "selected", in: selectionNamespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .frame(height: 32)
        .controlChrome()
    }
}

struct CapsuleTag: View {
    let text: String
    var tint: Color = AppTheme.accentText
    var symbol: String?

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .frame(height: 22)
        .background(tint.opacity(0.12), in: Capsule())
    }
}
