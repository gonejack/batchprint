import SwiftUI

struct ConfirmationView: View {
    @ObservedObject var model: PrintViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var closeHover = HoverState()
    @StateObject private var printHover = HoverState()

    var body: some View {
        VStack(spacing: 20) {
            header
            summary
            fileList
            footer
        }
        .padding(24)
        .frame(width: 520)
        .tint(AppTheme.accentText)
        .background {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                LinearGradient(
                    colors: [
                        AppTheme.accentText.opacity(0.045),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .center
                )
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 13) {
            AppMark(size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("Confirm Print")
                    .font(.system(size: 21, weight: .bold, design: .rounded))

                Text("Review the details below, then send everything to the print queue.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .background(
                        closeHover.isHovering ? Color.primary.opacity(0.075) : Color.clear,
                        in: Circle()
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .onHover { closeHover.isHovering = $0 }
            .help("Close")
        }
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "printer.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.accentText)
                    .frame(width: 27, height: 27)
                    .background(AppTheme.accentText.opacity(0.11), in: RoundedRectangle(cornerRadius: 7))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Printer")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(model.selectedPrinterDisplayName)
                        .font(.system(size: 12.5, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer(minLength: 10)

                CapsuleTag(
                    text: L10n.files(model.files.count),
                    tint: AppTheme.accentText,
                    symbol: "doc.on.doc.fill"
                )
            }
            .padding(.horizontal, 14)
            .frame(height: 50)

            Divider()
                .opacity(0.55)

            HStack(spacing: 8) {
                SummaryTile(
                    symbol: "rectangle.split.2x1",
                    label: L10n.text("Print Mode"),
                    value: model.duplex.longTitle
                )
                SummaryTile(
                    symbol: model.colorMode.symbolName,
                    label: L10n.text("Color"),
                    value: model.colorMode.longTitle
                )
                SummaryTile(
                    symbol: "doc",
                    label: L10n.text("Paper"),
                    value: "\(model.paper.title) · \(model.paper.dimensionText)"
                )
            }
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.42))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Files

    private var fileList: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.accentText)

                Text("Files")
                    .font(.system(size: 11.5, weight: .semibold))

                Text("\(model.files.count)")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .frame(height: 17)
                    .background(Color.primary.opacity(0.06), in: Capsule())

                Spacer()

                if let totalPageCount = model.totalKnownPageCount {
                    Text(L10n.format("Total %@", L10n.pages(totalPageCount)))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 13)
            .frame(height: 36)

            Divider()
                .opacity(0.5)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(model.files.enumerated()), id: \.element.id) { index, file in
                        HStack(spacing: 8) {
                            FileKindBadge(kind: file.kind, size: 22)

                            Text(file.name)
                                .font(.system(size: 11.5))
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer(minLength: 8)

                            Text(file.pageCount.map { L10n.pages($0) } ?? file.kind.title)
                                .font(.system(size: 9.5))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 13)
                        .frame(height: 34)

                        if index < model.files.count - 1 {
                            Divider()
                                .opacity(0.35)
                                .padding(.leading, 43)
                        }
                    }
                }
            }
            .frame(height: min(max(CGFloat(model.files.count) * 34, 34), 126))
        }
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.075), lineWidth: 1)
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "info.circle")
                    .font(.system(size: 9.5, weight: .medium))
                Text("Cancel to go back and adjust settings")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.tertiary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 17)
                    .frame(height: 36)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(ConfirmPressableButtonStyle())
            .focusable(false)
            .keyboardShortcut(.cancelAction)

            Button {
                model.startPrinting()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Start Printing")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(AppTheme.buttonText)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.regularMaterial)

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                Color.primary.opacity(printHover.isHovering ? 0.035 : 0)
                            )
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.07),
                    radius: 7,
                    y: 2
                )
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(ConfirmPressableButtonStyle())
            .focusable(false)
            .onHover { hovering in
                printHover.isHovering = hovering
            }
            .keyboardShortcut(.defaultAction)
        }
        .frame(height: 36)
    }
}

private struct SummaryTile: View {
    let symbol: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
                Text(label)
                    .font(.system(size: 9.5, weight: .medium))
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 11.5, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
    }
}

private struct ConfirmPressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
