import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

final class DropTargetState: ObservableObject {
    @Published var isDropTargeted = false
}

final class HoverState: ObservableObject {
    @Published var isHovering = false
}

struct ContentView: View {
    @ObservedObject var model: PrintViewModel
    @StateObject private var dropTargetState = DropTargetState()

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 10) {
                HeaderView(fileCount: model.files.count)

                if model.files.isEmpty {
                    DropAreaView(model: model, isDropTargeted: $dropTargetState.isDropTargeted)
                        .transition(.opacity)
                } else {
                    FileListCard(model: model)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                SettingsCard(model: model)

                Spacer(minLength: 4)

                FooterView(model: model)
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 660, minHeight: 520)
        .tint(AppTheme.accentText)
        .overlay(alignment: .top) {
            if let toast = model.toast {
                ToastView(toast: toast, onDismiss: model.dismissToast)
                    .padding(.top, 52)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .overlay {
            if let activity = model.printActivity {
                PrintingOverlay(activity: activity)
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.toast?.id)
        .animation(.easeOut(duration: 0.2), value: model.printActivity)
        .animation(.easeOut(duration: 0.2), value: model.files.count)
        .sheet(isPresented: $model.isConfirmationPresented) {
            ConfirmationView(model: model)
        }
        .alert(item: $model.alert) { alert in
            switch alert {
            case .noPrinter:
                return Alert(
                    title: Text("Printer Not Found"),
                    message: Text("Add a printer in System Settings › Printers & Scanners, then return here and refresh the list."),
                    primaryButton: .default(Text("Open Printer Settings")) {
                        model.openPrinterSettings()
                    },
                    secondaryButton: .cancel(Text("Later"))
                )
            case .printFailed(let message):
                return Alert(
                    title: Text("Print Failed"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            case .general(let message):
                return Alert(
                    title: Text("Notice"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

// MARK: - Background

private struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: [
                    AppTheme.accentText.opacity(colorScheme == .dark ? 0.10 : 0.055),
                    Color.clear,
                    AppTheme.accentText.opacity(colorScheme == .dark ? 0.05 : 0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.accentText.opacity(colorScheme == .dark ? 0.09 : 0.06))
                .frame(width: 520, height: 520)
                .blur(radius: 120)
                .offset(x: 340, y: -350)

            Circle()
                .fill(AppTheme.accentText.opacity(colorScheme == .dark ? 0.055 : 0.035))
                .frame(width: 440, height: 440)
                .blur(radius: 130)
                .offset(x: -360, y: 330)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Header

private struct HeaderView: View {
    let fileCount: Int

    var body: some View {
        HStack(spacing: 11) {
            AppMark(size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("BatchPrint")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                Text("Drop files, choose settings, and send everything to the print queue at once.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if fileCount > 0 {
                CapsuleTag(
                    text: L10n.files(fileCount),
                    tint: AppTheme.accentText,
                    symbol: "doc.on.doc.fill"
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 42)
    }
}

// MARK: - Drop area

private struct DropAreaView: View {
    @ObservedObject var model: PrintViewModel
    @Binding var isDropTargeted: Bool
    @StateObject private var hoverState = HoverState()
    @Environment(\.colorScheme) private var colorScheme

    private var headline: String {
        if isDropTargeted { return L10n.text("Release to Add") }
        return model.files.isEmpty
            ? L10n.text("Drop Files Here")
            : L10n.text("Keep Dropping More Files")
    }

    private var dropAreaHeight: CGFloat {
        model.files.isEmpty ? 270 : 110
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.accentText.opacity(isDropTargeted ? 0.22 : 0.13),
                                AppTheme.accentText.opacity(isDropTargeted ? 0.11 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: isDropTargeted ? "arrow.down.doc.fill" : "tray.and.arrow.down.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(AppTheme.accentText)
            }
            .frame(width: 54, height: 54)
            .scaleEffect(isDropTargeted ? 1.06 : 1)

            VStack(spacing: 3) {
                Text(headline)
                    .font(.system(size: 16.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Supports PDF, images, TXT and RTF · Click to choose files")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.accentText.opacity(isDropTargeted ? 0.12 : (hoverState.isHovering ? 0.065 : 0.045)),
                            AppTheme.accentText.opacity(isDropTargeted ? 0.06 : 0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    isDropTargeted ? AppTheme.accentText.opacity(0.9) : AppTheme.accentText.opacity(0.32),
                    style: StrokeStyle(
                        lineWidth: isDropTargeted ? 2 : 1.4,
                        lineCap: .round,
                        dash: [7, 6]
                    )
                )
        }
        .shadow(
            color: isDropTargeted
                ? AppTheme.accentText.opacity(0.14)
                : Color.black.opacity(colorScheme == .dark ? 0.24 : 0.035),
            radius: isDropTargeted ? 20 : 12,
            y: 6
        )
        .frame(height: dropAreaHeight)
        .scaleEffect(isDropTargeted ? 1.008 : 1)
        .animation(.easeOut(duration: 0.18), value: isDropTargeted)
        .animation(.easeOut(duration: 0.18), value: hoverState.isHovering)
        .onHover { hovering in
            hoverState.isHovering = hovering
        }
        .onTapGesture {
            guard model.canAddFiles else { return }
            model.presentOpenPanel()
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard model.canAddFiles, !urls.isEmpty else { return false }
            model.addFiles(urls, autoConfirm: true)
            return true
        } isTargeted: { targeted in
            withAnimation(.easeOut(duration: 0.16)) {
                isDropTargeted = targeted
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Add print files")
        .accessibilityHint("Drop PDF, image, text, or RTF files here, or click to choose files")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Files

private struct FileListCard: View {
    @ObservedObject var model: PrintViewModel
    @StateObject private var dropTargetState = DropTargetState()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(AppTheme.accentText)

                Text("Files")
                    .font(.system(size: 11.5, weight: .semibold))

                Text("\(model.files.count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(Color.primary.opacity(0.06), in: Capsule())

                Spacer()

                Text("Drop files here to add more")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                Button {
                    model.clearFiles()
                } label: {
                    Text("Clear")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(model.isPrinting)
                .help("Clear file list")
            }
            .padding(.horizontal, 13)
            .frame(height: 32)

            Divider()
                .opacity(0.55)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(model.files.enumerated()), id: \.element.id) { index, file in
                        FileRow(
                            file: file,
                            onRemove: { model.removeFile(file) },
                            onReveal: { model.revealInFinder(file) }
                        )

                        if index < model.files.count - 1 {
                            Divider()
                                .opacity(0.45)
                                .padding(.leading, 58)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .cardSurface(cornerRadius: 16)
        .overlay {
            if dropTargetState.isDropTargeted {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        AppTheme.accentText.opacity(0.9),
                        style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [7, 6])
                    )
            }
        }
        .overlay {
            if dropTargetState.isDropTargeted {
                Label("Release to add files", systemImage: "plus.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.accentText)
                    .padding(.horizontal, 13)
                    .frame(height: 32)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: Color.black.opacity(0.10), radius: 10, y: 4)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard model.canAddFiles, !urls.isEmpty else { return false }
            model.addFiles(urls, autoConfirm: false)
            return true
        } isTargeted: { targeted in
            withAnimation(.easeOut(duration: 0.16)) {
                dropTargetState.isDropTargeted = targeted
            }
        }
        .help("Drop more files here")
    }
}

private struct FileRow: View {
    let file: PrintFile
    let onRemove: () -> Void
    let onReveal: () -> Void

    @StateObject private var hoverState = HoverState()

    var body: some View {
        HStack(spacing: 10) {
            FileKindBadge(kind: file.kind, size: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(file.name)
                    .font(.system(size: 11.5, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(file.detailText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(hoverState.isHovering ? Color.secondary : Color.secondary.opacity(0.42))
            }
            .buttonStyle(.plain)
            .help("Remove file")
        }
        .padding(.horizontal, 13)
        .frame(height: 42)
        .background(hoverState.isHovering ? Color.primary.opacity(0.035) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            hoverState.isHovering = hovering
        }
        .onTapGesture(count: 2, perform: onReveal)
        .help(file.url.path)
    }
}

// MARK: - Settings

private struct SettingsCard: View {
    @ObservedObject var model: PrintViewModel
    @StateObject private var refreshHover = HoverState()

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            printerField
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                SettingLabel(title: L10n.text("Print Mode"))
                SegmentedControl(
                    options: DuplexOption.allCases,
                    selection: $model.duplex,
                    title: { $0.title },
                    symbol: { $0.symbolName }
                )
                .help("Duplex printing requires a printer that supports automatic duplex.")
            }
            .frame(width: 140)

            VStack(alignment: .leading, spacing: 6) {
                SettingLabel(title: L10n.text("Color"))
                SegmentedControl(
                    options: PrintColorMode.allCases,
                    selection: $model.colorMode,
                    title: { $0.title },
                    symbol: { $0.symbolName }
                )
                .help("Black & white mode converts documents to grayscale first.")
            }
            .frame(width: 132)

            VStack(alignment: .leading, spacing: 6) {
                SettingLabel(title: L10n.text("Paper"))
                Menu {
                    ForEach(PaperOption.allCases) { option in
                        Button {
                            model.paper = option
                        } label: {
                            if model.paper == option {
                                Label(option.menuTitle, systemImage: "checkmark")
                            } else {
                                Text(option.menuTitle)
                            }
                        }
                    }
                } label: {
                    MenuControlLabel(
                        symbol: nil,
                        text: model.paper.title
                    )
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(height: 32)
                .help(model.paper.dimensionText)
            }
            .frame(width: 110)
        }
        .padding(12)
        .cardSurface(cornerRadius: 14)
    }

    private var printerField: some View {
        VStack(alignment: .leading, spacing: 6) {
            SettingLabel(title: L10n.text("Printer"))

            HStack(spacing: 7) {
                Menu {
                    if model.printerNames.isEmpty {
                        Text("No printers available")
                    } else {
                        ForEach(model.printerNames, id: \.self) { name in
                            Button {
                                model.selectedPrinterName = name
                            } label: {
                                if name == model.selectedPrinterName {
                                    Label(model.displayName(for: name), systemImage: "checkmark")
                                } else {
                                    Text(model.displayName(for: name))
                                }
                            }
                        }
                    }

                    Divider()

                    Button("Refresh Printer List") {
                        model.refreshPrinters(announce: true)
                    }
                    Button("Open Printer Settings…") {
                        model.openPrinterSettings()
                    }
                } label: {
                    MenuControlLabel(
                        symbol: "printer.fill",
                        text: model.selectedPrinterDisplayName,
                        isWarning: !model.hasPrinter
                    )
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .frame(maxWidth: .infinity)

                Button {
                    model.refreshPrinters(announce: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(refreshHover.isHovering ? 0.06 : 0))
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .onHover { refreshHover.isHovering = $0 }
                .help("Refresh printer list")
            }
        }
    }
}

// MARK: - Footer

private struct FooterView: View {
    @ObservedObject var model: PrintViewModel
    @StateObject private var hoverState = HoverState()
    @Environment(\.colorScheme) private var colorScheme

    private var hint: String {
        if !model.hasPrinter {
            return L10n.text("No printer detected. Add one in System Settings first.")
        }
        if model.files.isEmpty {
            return L10n.text("You'll review everything before printing.")
        }
        return L10n.text("You'll review everything before printing, and you can go back to adjust settings.")
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(model.files.isEmpty ? Color.secondary.opacity(0.4) : AppTheme.accentText)
                        .frame(width: 6, height: 6)

                    Text(model.summaryText)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }

                Text(hint)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            if !model.hasPrinter {
                Button {
                    model.openPrinterSettings()
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Button {
                model.requestConfirmation()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "printer.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(model.primaryButtonTitle)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(model.canPrint ? AppTheme.buttonText : Color.secondary)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background {
                    ZStack {
                        if model.canPrint {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.regularMaterial)
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.035))
                        }

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                Color.primary.opacity(
                                    hoverState.isHovering && model.canPrint ? 0.035 : 0
                                )
                            )
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            Color.primary.opacity(model.canPrint ? 0.10 : 0.05),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: model.canPrint
                        ? Color.black.opacity(colorScheme == .dark ? 0.22 : 0.07)
                        : .clear,
                    radius: 7,
                    y: 2
                )
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!model.canPrint)
            .onHover { hovering in
                hoverState.isHovering = hovering
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Print (⌘↩)")
        }
        .frame(height: 34)
    }
}

private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Toast

private struct ToastView: View {
    let toast: AppToast
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: toast.kind.symbolName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(toast.kind.tint)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.primary)

                if let detail = toast.detail {
                    Text(detail)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: 440, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(toast.kind.tint.opacity(0.24), lineWidth: 1)
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.32 : 0.12),
            radius: 18,
            y: 8
        )
    }
}

// MARK: - Printing overlay

private struct PrintingOverlay: View {
    let activity: PrintActivity
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.black.opacity(colorScheme == .dark ? 0.38 : 0.18)
                .ignoresSafeArea()

            VStack(spacing: 17) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentText.opacity(0.12))
                        .frame(width: 58, height: 58)

                    Image(systemName: activity.phase == .sending ? "paperplane.fill" : "printer.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.accentText)
                }

                VStack(spacing: 5) {
                    Text(activity.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))

                    Text(activity.detail)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: 270)
                }

                if let progress = activity.progress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(AppTheme.accentText)
                        .frame(width: 224)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }

                Text("Please wait and keep this window open")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .frame(width: 330)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.20), radius: 35, y: 16)
        }
    }
}
