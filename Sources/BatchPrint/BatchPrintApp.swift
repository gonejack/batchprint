import AppKit
import SwiftUI

@main
struct BatchPrintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = PrintViewModel.shared

    var body: some Scene {
        Window("BatchPrint", id: "main") {
            ContentView(model: model)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 700, height: 540)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Files…") {
                    model.presentOpenPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(!model.canAddFiles)

                Button("Clear File List") {
                    model.clearFiles()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(model.files.isEmpty || model.isPrinting)
            }

            CommandGroup(replacing: .printItem) {
                Button("Print…") {
                    model.requestConfirmation()
                }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(!model.canPrint)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hasClearedInitialFocus = false
    private let compactWindowSize = NSSize(width: 700, height: 540)
    private let compactWindowSizeKey = "com.youi.batchprint.compactWindowSizeApplied"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        positionWindow(after: 0.15)
        positionWindow(after: 0.8)
    }

    private func positionWindow(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard let window = NSApp.windows.first(where: { $0.canBecomeMain }) else { return }
            window.title = L10n.text("BatchPrint")
            window.minSize = NSSize(width: 660, height: 520)

            // Existing installs restore the old, much larger window frame.
            // Apply the compact size once; later launches keep user resizing.
            if !UserDefaults.standard.bool(forKey: self.compactWindowSizeKey) {
                UserDefaults.standard.set(true, forKey: self.compactWindowSizeKey)
                window.setContentSize(self.compactWindowSize)
            }

            let mouseLocation = NSEvent.mouseLocation
            let targetScreen = NSScreen.screens.first {
                NSMouseInRect(mouseLocation, $0.frame, false)
            } ?? NSScreen.main ?? NSScreen.screens.first

            if let visibleFrame = targetScreen?.visibleFrame {
                let size = window.frame.size
                let frame = NSRect(
                    x: visibleFrame.midX - size.width / 2,
                    y: visibleFrame.midY - size.height / 2,
                    width: size.width,
                    height: size.height
                )
                window.setFrame(frame, display: true)
            }

            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            // Avoid an initial keyboard-focus ring on the first control.
            if !self.hasClearedInitialFocus {
                self.hasClearedInitialFocus = true
                DispatchQueue.main.async {
                    window.makeFirstResponder(nil)
                }
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard !urls.isEmpty else { return }
        Task { @MainActor in
            PrintViewModel.shared.addFiles(urls, autoConfirm: true)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
