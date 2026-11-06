import AppKit
import Combine
import ImageIO
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class PrintViewModel: ObservableObject {
    static let shared = PrintViewModel()

    // Files
    @Published private(set) var files: [PrintFile] = []

    // Printers
    @Published private(set) var printerNames: [String] = []
    @Published private(set) var printerDisplayNames: [String: String] = [:]
    @Published var selectedPrinterName: String = ""

    // Options
    @Published var duplex: DuplexOption = .simplex
    @Published var colorMode: PrintColorMode = .color
    @Published var paper: PaperOption = .a4

    // Presentation state
    @Published var isConfirmationPresented = false
    @Published var isPrinting = false
    @Published var printActivity: PrintActivity?
    @Published var toast: AppToast?
    @Published var alert: AppAlert?

    private var toastDismissWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    init() {
        refreshPrinters()

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, !self.isPrinting else { return }
                self.refreshPrinters()
            }
            .store(in: &cancellables)
    }

    // MARK: - Derived state

    var hasPrinter: Bool {
        !selectedPrinterName.isEmpty && printerNames.contains(selectedPrinterName)
    }

    var canPrint: Bool {
        !files.isEmpty && hasPrinter && !isPrinting
    }

    var canAddFiles: Bool {
        !isPrinting
    }

    var primaryButtonTitle: String {
        L10n.printTitle(files.count)
    }

    var totalKnownPageCount: Int? {
        guard !files.isEmpty else { return nil }
        let counts = files.compactMap(\.pageCount)
        guard counts.count == files.count else { return nil }
        return counts.reduce(0, +)
    }

    var summaryText: String {
        guard !files.isEmpty else { return L10n.text("Drop files to start printing") }

        var parts = [L10n.files(files.count)]
        if let totalKnownPageCount {
            parts.append(L10n.format("Total %@", L10n.pages(totalKnownPageCount)))
        }
        parts.append(paper.title)
        if duplex == .duplex {
            parts.append(L10n.text("Duplex"))
        }
        if colorMode == .grayscale {
            parts.append(L10n.text("Black & White"))
        }
        return parts.joined(separator: " · ")
    }

    var selectedPrinterDisplayName: String {
        hasPrinter ? displayName(for: selectedPrinterName) : L10n.text("No Printer Found")
    }

    func displayName(for queueName: String) -> String {
        printerDisplayNames[queueName] ?? queueName
    }

    var configuration: PrintConfiguration? {
        guard hasPrinter else { return nil }
        return PrintConfiguration(
            printerName: selectedPrinterName,
            printerDisplayName: displayName(for: selectedPrinterName),
            duplex: duplex,
            colorMode: colorMode,
            paper: paper
        )
    }

    // MARK: - Printers

    func refreshPrinters(announce: Bool = false) {
        let discovered = PrinterCatalog.configuredPrinters()
        let names = discovered.map(\.queueName)
        printerNames = names

        var displayNames: [String: String] = [:]
        for printer in discovered {
            displayNames[printer.queueName] = printer.displayName
        }
        printerDisplayNames = displayNames

        if !names.contains(selectedPrinterName) {
            if let defaultPrinter = discovered.first(where: \.isDefault) {
                selectedPrinterName = defaultPrinter.queueName
            } else {
                selectedPrinterName = names.first ?? ""
            }
        }

        guard announce else { return }
        if names.isEmpty {
            showToast(
                kind: .warning,
                title: L10n.text("Printer Not Found"),
                detail: L10n.text("Add and enable a printer in System Settings first.")
            )
        } else {
            showToast(
                kind: .success,
                title: L10n.text("Printer List Refreshed"),
                detail: L10n.format("Printers found: %lld", names.count)
            )
        }
    }

    func openPrinterSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.Print-Scan-Settings.extension"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - File handling

    func addFiles(_ urls: [URL], autoConfirm: Bool = true) {
        guard !urls.isEmpty else { return }

        let wasEmpty = files.isEmpty
        var knownPaths = Set(files.map { $0.url.standardizedFileURL.path })
        var accepted: [PrintFile] = []
        var duplicateCount = 0
        var skippedCount = 0

        for url in urls {
            let standardizedURL = url.standardizedFileURL

            guard !knownPaths.contains(standardizedURL.path) else {
                duplicateCount += 1
                continue
            }

            guard let file = inspectFile(at: standardizedURL) else {
                skippedCount += 1
                continue
            }

            accepted.append(file)
            knownPaths.insert(standardizedURL.path)
        }

        guard !accepted.isEmpty else {
            if duplicateCount > 0 {
                showToast(
                    kind: .info,
                    title: L10n.text("Files Already in the List"),
                    detail: L10n.text("No new files were added.")
                )
            } else if skippedCount > 0 {
                showToast(
                    kind: .warning,
                    title: L10n.text("No Printable Files"),
                    detail: L10n.text("Supports PDF, images, plain text, and RTF files.")
                )
            }
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            files.append(contentsOf: accepted)
        }

        if skippedCount > 0 {
            showToast(
                kind: .warning,
                title: L10n.format("Skipped %@", L10n.files(skippedCount)),
                detail: L10n.text("Only readable PDF, image, plain text, and RTF files are supported.")
            )
        } else if duplicateCount > 0 {
            showToast(
                kind: .info,
                title: L10n.format("Duplicate files ignored: %lld", duplicateCount)
            )
        }

        if wasEmpty && autoConfirm {
            if hasPrinter {
                scheduleAutomaticConfirmation()
            } else {
                showToast(
                    kind: .warning,
                    title: L10n.text("Files Added, but No Printer Found"),
                    detail: L10n.text("Add a printer in System Settings first.")
                )
            }
        }
    }

    func removeFile(_ file: PrintFile) {
        guard !isPrinting else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            files.removeAll { $0.id == file.id }
        }
    }

    func clearFiles() {
        guard !isPrinting else { return }
        isConfirmationPresented = false
        withAnimation(.easeOut(duration: 0.18)) {
            files.removeAll()
        }
    }

    func revealInFinder(_ file: PrintFile) {
        NSWorkspace.shared.activateFileViewerSelecting([file.url])
    }

    private func inspectFile(at url: URL) -> PrintFile? {
        let values = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .fileSizeKey,
            .contentTypeKey
        ])

        if values?.isDirectory == true { return nil }
        guard FileManager.default.isReadableFile(atPath: url.path) else { return nil }
        guard let kind = PrintFileKind.detect(for: url) else { return nil }

        var pageCount: Int?

        switch kind {
        case .pdf:
            guard let document = PDFDocument(url: url),
                  !document.isLocked,
                  document.allowsPrinting,
                  document.pageCount > 0 else {
                return nil
            }
            pageCount = document.pageCount

        case .image:
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  CGImageSourceGetCount(source) > 0 else {
                return nil
            }
            pageCount = 1

        case .text, .richText:
            pageCount = nil
        }

        return PrintFile(
            url: url,
            kind: kind,
            pageCount: pageCount,
            byteCount: Int64(values?.fileSize ?? 0)
        )
    }

    func presentOpenPanel() {
        guard canAddFiles else { return }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = PrintFileKind.supportedContentTypes
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.canCreateDirectories = false
        panel.prompt = L10n.text("Add")
        panel.message = L10n.text("Choose files to batch print")

        panel.begin { [weak self] response in
            guard response == .OK else { return }
            let urls = panel.urls
            Task { @MainActor [weak self] in
                self?.addFiles(urls, autoConfirm: true)
            }
        }
    }

    // MARK: - Confirmation and printing

    func requestConfirmation() {
        guard !files.isEmpty else {
            showToast(kind: .info, title: L10n.text("Add files before printing"))
            return
        }
        guard hasPrinter else {
            alert = .noPrinter
            return
        }
        isConfirmationPresented = true
    }

    func startPrinting() {
        guard !isPrinting else { return }
        guard let configuration else {
            isConfirmationPresented = false
            alert = .noPrinter
            return
        }
        guard !files.isEmpty else {
            isConfirmationPresented = false
            return
        }

        isConfirmationPresented = false
        isPrinting = true

        let fileSnapshot = files
        let configurationSnapshot = configuration
        printActivity = PrintActivity(
            phase: .preparing,
            title: L10n.text("Preparing to Print"),
            detail: L10n.format("Merging %@…", L10n.files(fileSnapshot.count)),
            progress: nil
        )

        DispatchQueue.global(qos: .userInitiated).async {
            var preparedURL: URL?

            do {
                let prepared = try PrintService.preparePDF(
                    files: fileSnapshot,
                    configuration: configurationSnapshot
                ) { index, total, fileName in
                    guard !fileName.isEmpty else { return }
                    DispatchQueue.main.async {
                        guard self.isPrinting else { return }
                        self.printActivity = PrintActivity(
                            phase: .preparing,
                            title: L10n.text("Preparing to Print"),
                            detail: L10n.format("Processing %lld/%lld: %@", index + 1, total, fileName),
                            progress: total > 0 ? Double(index) / Double(total) : nil
                        )
                    }
                }
                preparedURL = prepared.fileURL

                DispatchQueue.main.async {
                    guard self.isPrinting else { return }
                    self.printActivity = PrintActivity(
                        phase: .sending,
                        title: L10n.text("Sending to Printer"),
                        detail: L10n.format("%@ · %@", configurationSnapshot.printerDisplayName, L10n.pages(prepared.pageCount)),
                        progress: nil
                    )
                }

                let submitted = try PrintService.submit(
                    job: prepared,
                    configuration: configurationSnapshot,
                    fileCount: fileSnapshot.count
                )

                if let preparedURL {
                    try? FileManager.default.removeItem(at: preparedURL)
                }

                DispatchQueue.main.async {
                    self.finishPrinting(
                        with: submitted,
                        configuration: configurationSnapshot
                    )
                }
            } catch {
                if let preparedURL {
                    try? FileManager.default.removeItem(at: preparedURL)
                }

                DispatchQueue.main.async {
                    self.finishPrinting(with: error)
                }
            }
        }
    }

    private func finishPrinting(
        with submitted: SubmittedPrintJob,
        configuration: PrintConfiguration
    ) {
        isPrinting = false
        printActivity = nil

        var detailParts = [configuration.printerDisplayName, L10n.pages(submitted.pageCount)]
        if let jobID = submitted.jobID {
            detailParts.append(L10n.format("Job %@", jobID))
        }

        showToast(
            kind: .success,
            title: L10n.text("Sent to Print Queue"),
            detail: detailParts.joined(separator: " · ")
        )
    }

    private func finishPrinting(with error: Error) {
        isPrinting = false
        printActivity = nil
        alert = .printFailed(error.localizedDescription)
    }

    private func scheduleAutomaticConfirmation() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 420_000_000)
            guard let self,
                  !self.isPrinting,
                  !self.isConfirmationPresented,
                  self.hasPrinter,
                  !self.files.isEmpty else {
                return
            }
            self.isConfirmationPresented = true
        }
    }

    // MARK: - Toasts

    private func showToast(kind: AppToast.Kind, title: String, detail: String? = nil) {
        let toast = AppToast(kind: kind, title: title, detail: detail)
        withAnimation(.easeOut(duration: 0.18)) {
            self.toast = toast
        }

        toastDismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.toast?.id == toast.id else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                self.toast = nil
            }
        }
        toastDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2, execute: workItem)
    }

    func dismissToast() {
        toastDismissWorkItem?.cancel()
        withAnimation(.easeIn(duration: 0.18)) {
            toast = nil
        }
    }
}
