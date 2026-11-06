import AppKit
import CoreText
import ImageIO
import PDFKit
import Quartz

enum PrintServiceError: LocalizedError {
    case cannotOpenPDF(String)
    case lockedPDF(String)
    case printRestricted(String)
    case emptyDocument(String)
    case cannotDecodeImage(String)
    case cannotReadText(String)
    case cannotCreatePDF
    case printerUnavailable
    case printCommandNotFound
    case printCommandFailed(String)

    var errorDescription: String? {
        switch self {
        case .cannotOpenPDF(let name):
            return L10n.format("Unable to open PDF: %@", name)
        case .lockedPDF(let name):
            return L10n.format("This PDF is password-protected and cannot be printed: %@", name)
        case .printRestricted(let name):
            return L10n.format("Printing is disabled for this PDF: %@", name)
        case .emptyDocument(let name):
            return L10n.format("No printable content found in: %@", name)
        case .cannotDecodeImage(let name):
            return L10n.format("Unable to read image: %@", name)
        case .cannotReadText(let name):
            return L10n.format("Unable to read text encoding: %@", name)
        case .cannotCreatePDF:
            return L10n.text("Unable to create a temporary print file. Check disk space.")
        case .printerUnavailable:
            return L10n.text("The selected printer is unavailable. Choose another printer.")
        case .printCommandNotFound:
            return L10n.text("The system print service is unavailable.")
        case .printCommandFailed(let message):
            return message.isEmpty ? L10n.text("Failed to submit the print job.") : message
        }
    }
}

struct PreparedPrintJob {
    let fileURL: URL
    let pageCount: Int
}

struct SubmittedPrintJob {
    let jobID: String?
    let message: String
    let pageCount: Int
}

enum PrintService {
    private static let systemGrayFilterURL = URL(
        fileURLWithPath: "/System/Library/Filters/Gray Tone.qfilter"
    )

    // MARK: - PDF preparation

    static func preparePDF(
        files: [PrintFile],
        configuration: PrintConfiguration,
        progress: ((Int, Int, String) -> Void)? = nil
    ) throws -> PreparedPrintJob {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BatchPrint-\(UUID().uuidString).pdf")

        var mediaBox = CGRect(origin: .zero, size: configuration.paper.size)
        let metadata: [CFString: Any] = [
            kCGPDFContextCreator: L10n.text("BatchPrint"),
            kCGPDFContextTitle: L10n.text("BatchPrint")
        ]

        guard let context = CGContext(
            outputURL as CFURL,
            mediaBox: &mediaBox,
            metadata as CFDictionary
        ) else {
            throw PrintServiceError.cannotCreatePDF
        }

        // The built-in Gray Tone Quartz filter preserves vector content while
        // converting the whole document to grayscale.
        if configuration.colorMode == .grayscale,
           let filter = QuartzFilter(url: systemGrayFilterURL) {
            _ = filter.apply(to: context)
        }

        var generatedPages = 0
        var completed = false

        defer {
            context.closePDF()
            if !completed {
                try? FileManager.default.removeItem(at: outputURL)
            }
        }

        for (index, file) in files.enumerated() {
            progress?(index, files.count, file.name)

            try autoreleasepool {
                switch file.kind {
                case .pdf:
                    generatedPages += try appendPDF(
                        at: file.url,
                        name: file.name,
                        context: context,
                        configuration: configuration
                    )
                case .image:
                    generatedPages += try appendImage(
                        at: file.url,
                        name: file.name,
                        context: context,
                        configuration: configuration
                    )
                case .text, .richText:
                    generatedPages += try appendText(
                        file: file,
                        context: context,
                        configuration: configuration
                    )
                }
            }
        }

        progress?(files.count, files.count, "")

        guard generatedPages > 0 else {
            throw PrintServiceError.emptyDocument(files.first?.name ?? L10n.text("Selected Files"))
        }

        completed = true
        return PreparedPrintJob(fileURL: outputURL, pageCount: generatedPages)
    }

    private static func appendPDF(
        at url: URL,
        name: String,
        context: CGContext,
        configuration: PrintConfiguration
    ) throws -> Int {
        guard let document = PDFDocument(url: url) else {
            throw PrintServiceError.cannotOpenPDF(name)
        }
        guard !document.isLocked else {
            throw PrintServiceError.lockedPDF(name)
        }
        guard document.allowsPrinting else {
            throw PrintServiceError.printRestricted(name)
        }
        guard document.pageCount > 0 else {
            throw PrintServiceError.emptyDocument(name)
        }

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            beginPage(context: context, paperSize: configuration.paper.size)
            draw(page: page, context: context, paperSize: configuration.paper.size)
            context.endPDFPage()
        }

        return document.pageCount
    }

    private static func appendImage(
        at url: URL,
        name: String,
        context: CGContext,
        configuration: PrintConfiguration
    ) throws -> Int {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw PrintServiceError.cannotDecodeImage(name)
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 16_000
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            throw PrintServiceError.cannotDecodeImage(name)
        }

        beginPage(context: context, paperSize: configuration.paper.size)

        let paperRect = CGRect(origin: .zero, size: configuration.paper.size)
        let margin: CGFloat = 36
        let contentRect = paperRect.insetBy(dx: margin, dy: margin)
        let imageSize = CGSize(width: image.width, height: image.height)
        let targetRect = aspectFit(imageSize, in: contentRect)

        context.saveGState()
        context.interpolationQuality = .high
        context.draw(image, in: targetRect)
        context.restoreGState()

        context.endPDFPage()
        return 1
    }

    private static func appendText(
        file: PrintFile,
        context: CGContext,
        configuration: PrintConfiguration
    ) throws -> Int {
        let attributedText = try attributedText(for: file)
        guard attributedText.length > 0 else {
            throw PrintServiceError.emptyDocument(file.name)
        }

        let paperRect = CGRect(origin: .zero, size: configuration.paper.size)
        let contentRect = paperRect.insetBy(dx: 54, dy: 54)
        let framesetter = CTFramesetterCreateWithAttributedString(
            attributedText as CFAttributedString
        )

        var location = 0
        var pageCount = 0

        while location < attributedText.length {
            beginPage(context: context, paperSize: configuration.paper.size)

            let path = CGPath(rect: contentRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: location, length: 0),
                path,
                nil
            )
            CTFrameDraw(frame, context)

            let visibleRange = CTFrameGetVisibleStringRange(frame)
            context.endPDFPage()
            pageCount += 1

            guard visibleRange.length > 0 else { break }
            location += visibleRange.length
        }

        guard pageCount > 0 else {
            throw PrintServiceError.emptyDocument(file.name)
        }
        return pageCount
    }

    private static func attributedText(for file: PrintFile) throws -> NSAttributedString {
        switch file.kind {
        case .richText:
            do {
                let data = try Data(contentsOf: file.url)
                return try NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
                )
            } catch {
                throw PrintServiceError.cannotReadText(file.name)
            }

        case .text:
            let data: Data
            do {
                data = try Data(contentsOf: file.url)
            } catch {
                throw PrintServiceError.cannotReadText(file.name)
            }

            guard let text = decodeText(data) else {
                throw PrintServiceError.cannotReadText(file.name)
            }

            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 3
            paragraph.paragraphSpacing = 6
            paragraph.lineBreakMode = .byWordWrapping

            return NSAttributedString(
                string: text,
                attributes: [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.black,
                    .paragraphStyle: paragraph
                ]
            )

        default:
            throw PrintServiceError.cannotReadText(file.name)
        }
    }

    private static func decodeText(_ data: Data) -> String? {
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .isoLatin1,
            .windowsCP1252
        ]

        for encoding in encodings {
            if let value = String(data: data, encoding: encoding) {
                return value
            }
        }

        let gb18030 = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            )
        )
        return String(data: data, encoding: gb18030)
    }

    private static func beginPage(context: CGContext, paperSize: CGSize) {
        context.beginPDFPage(nil)
        context.saveGState()
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: paperSize))
        context.restoreGState()
    }

    private static func draw(page: PDFPage, context: CGContext, paperSize: CGSize) {
        page.displaysAnnotations = true

        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return }

        let rotated = page.rotation % 180 != 0
        let displaySize = rotated
            ? CGSize(width: bounds.height, height: bounds.width)
            : bounds.size

        let paperRect = CGRect(origin: .zero, size: paperSize)
        let targetRect = aspectFit(displaySize, in: paperRect)
        let scale = targetRect.width / displaySize.width

        context.saveGState()
        context.clip(to: paperRect)
        context.translateBy(x: targetRect.minX, y: targetRect.minY)
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()
    }

    private static func aspectFit(_ size: CGSize, in rect: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return rect }
        let scale = min(rect.width / size.width, rect.height / size.height)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: rect.midX - targetSize.width / 2,
            y: rect.midY - targetSize.height / 2,
            width: targetSize.width,
            height: targetSize.height
        )
    }

    // MARK: - CUPS queue

    static func submit(
        job: PreparedPrintJob,
        configuration: PrintConfiguration,
        fileCount: Int,
        lpExecutableURL: URL = URL(fileURLWithPath: "/usr/bin/lp")
    ) throws -> SubmittedPrintJob {
        guard !configuration.printerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PrintServiceError.printerUnavailable
        }

        let process = Process()
        process.executableURL = lpExecutableURL

        let jobName = L10n.format("BatchPrint · %lld Files", fileCount)
        process.arguments = [
            "-d", configuration.printerName,
            "-n", "1",
            "-o", "media=\(configuration.paper.cupsMedia)",
            "-o", "sides=\(configuration.duplex.cupsValue)",
            "-o", "print-color-mode=\(configuration.colorMode.cupsValue)",
            "-o", "job-name=\(jobName)",
            job.fileURL.path
        ]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        guard FileManager.default.isExecutableFile(atPath: process.executableURL!.path) else {
            throw PrintServiceError.printCommandNotFound
        }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw PrintServiceError.printCommandFailed(error.localizedDescription)
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            let message = errorOutput.isEmpty ? output : errorOutput
            throw PrintServiceError.printCommandFailed(message)
        }

        let jobID = extractJobID(from: output)
        return SubmittedPrintJob(
            jobID: jobID,
            message: output,
            pageCount: job.pageCount
        )
    }

    private static func extractJobID(from output: String) -> String? {
        guard let range = output.range(of: "request id is ") else { return nil }
        let remainder = output[range.upperBound...]
        return remainder.split(separator: " ").first.map(String.init)
    }
}
