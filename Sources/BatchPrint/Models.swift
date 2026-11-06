import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Print options

enum DuplexOption: String, CaseIterable, Identifiable {
    case simplex
    case duplex

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simplex: return L10n.text("Single")
        case .duplex: return L10n.text("Double")
        }
    }

    var longTitle: String {
        switch self {
        case .simplex: return L10n.text("Single-sided")
        case .duplex: return L10n.text("Double-sided (Long Edge)")
        }
    }

    var symbolName: String {
        switch self {
        case .simplex: return "rectangle"
        case .duplex: return "rectangle.split.2x1"
        }
    }

    var cupsValue: String {
        switch self {
        case .simplex: return "one-sided"
        case .duplex: return "two-sided-long-edge"
        }
    }
}

enum PrintColorMode: String, CaseIterable, Identifiable {
    case color
    case grayscale

    var id: String { rawValue }

    var title: String {
        switch self {
        case .color: return L10n.text("Color")
        case .grayscale: return L10n.text("B&W")
        }
    }

    var longTitle: String {
        switch self {
        case .color: return L10n.text("Color")
        case .grayscale: return L10n.text("Black & White (Grayscale)")
        }
    }

    var symbolName: String {
        switch self {
        case .color: return "paintpalette.fill"
        case .grayscale: return "circle.lefthalf.filled"
        }
    }

    var cupsValue: String {
        switch self {
        case .color: return "color"
        case .grayscale: return "monochrome"
        }
    }
}

enum PaperOption: String, CaseIterable, Identifiable {
    case a4
    case a3
    case a5
    case b5
    case letter
    case legal
    case photo4x6

    var id: String { rawValue }

    var title: String {
        switch self {
        case .a4: return "A4"
        case .a3: return "A3"
        case .a5: return "A5"
        case .b5: return "B5"
        case .letter: return "Letter"
        case .legal: return "Legal"
        case .photo4x6: return "4 × 6"
        }
    }

    var dimensionText: String {
        switch self {
        case .a4: return "210 × 297 mm"
        case .a3: return "297 × 420 mm"
        case .a5: return "148 × 210 mm"
        case .b5: return "176 × 250 mm"
        case .letter: return "8.5 × 11 in"
        case .legal: return "8.5 × 14 in"
        case .photo4x6: return "4 × 6 in"
        }
    }

    var menuTitle: String {
        switch self {
        case .photo4x6: return L10n.text("4 × 6 Photo")
        default: return "\(title) · \(dimensionText)"
        }
    }

    /// Page size in PDF points (1 point = 1/72 inch).
    var size: CGSize {
        switch self {
        case .a4:
            return CGSize(width: 595.276, height: 841.89)
        case .a3:
            return CGSize(width: 841.89, height: 1190.551)
        case .a5:
            return CGSize(width: 419.528, height: 595.276)
        case .b5:
            return CGSize(width: 498.898, height: 708.661)
        case .letter:
            return CGSize(width: 612, height: 792)
        case .legal:
            return CGSize(width: 612, height: 1008)
        case .photo4x6:
            return CGSize(width: 288, height: 432)
        }
    }

    /// PWG/IPP media keyword understood by CUPS.
    var cupsMedia: String {
        switch self {
        case .a4: return "iso-a4"
        case .a3: return "iso-a3"
        case .a5: return "iso-a5"
        case .b5: return "iso-b5"
        case .letter: return "na_letter"
        case .legal: return "na_legal"
        case .photo4x6: return "na_index-4x6"
        }
    }
}

struct PrintConfiguration {
    /// CUPS queue name passed to `lp -d`.
    let printerName: String
    /// Friendly name used in status messages and the confirmation sheet.
    let printerDisplayName: String
    let duplex: DuplexOption
    let colorMode: PrintColorMode
    let paper: PaperOption
}

// MARK: - Files

enum PrintFileKind: String {
    case pdf
    case image
    case text
    case richText

    static var supportedContentTypes: [UTType] {
        [.pdf, .image, .plainText, .rtf]
    }

    static func detect(for url: URL) -> PrintFileKind? {
        let contentType = (try? url.resourceValues(forKeys: [.contentTypeKey]))?.contentType
        if let contentType {
            if contentType.conforms(to: .pdf) { return .pdf }
            if contentType.conforms(to: .image) { return .image }
            if contentType.conforms(to: .rtf) { return .richText }
            if contentType.conforms(to: .plainText) { return .text }
        }

        switch url.pathExtension.lowercased() {
        case "pdf": return .pdf
        case "png", "jpg", "jpeg", "tif", "tiff", "heic", "heif", "gif", "bmp", "webp":
            return .image
        case "rtf": return .richText
        case "txt", "text", "md", "csv", "log": return .text
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .pdf: return "PDF"
        case .image: return L10n.text("Image")
        case .text: return L10n.text("Text")
        case .richText: return "RTF"
        }
    }

    var symbolName: String {
        switch self {
        case .pdf: return "doc.richtext.fill"
        case .image: return "photo.fill"
        case .text: return "doc.text.fill"
        case .richText: return "doc.text.image.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pdf: return Color(red: 0.94, green: 0.32, blue: 0.26)
        case .image: return Color(red: 0.96, green: 0.58, blue: 0.18)
        case .text: return AppTheme.accentText
        case .richText: return Color(red: 0.58, green: 0.38, blue: 0.92)
        }
    }
}

struct PrintFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let kind: PrintFileKind
    let pageCount: Int?
    let byteCount: Int64

    var name: String { url.lastPathComponent }

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }

    var detailText: String {
        var parts = [kind.title]
        if let pageCount {
            parts.append(L10n.pages(pageCount))
        }
        parts.append(sizeText)
        return parts.joined(separator: " · ")
    }
}

// MARK: - UI state

struct AppToast: Identifiable, Equatable {
    enum Kind: Equatable {
        case success
        case info
        case warning
        case error

        var symbolName: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            }
        }

        var tint: Color {
            switch self {
            case .success: return Color(red: 0.16, green: 0.68, blue: 0.38)
            case .info: return AppTheme.accentText
            case .warning: return Color(red: 0.94, green: 0.58, blue: 0.12)
            case .error: return Color(red: 0.91, green: 0.27, blue: 0.24)
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let detail: String?
}

enum AppAlert: Identifiable {
    case noPrinter
    case printFailed(String)
    case general(String)

    var id: String {
        switch self {
        case .noPrinter: return "noPrinter"
        case .printFailed(let message): return "printFailed-\(message)"
        case .general(let message): return "general-\(message)"
        }
    }
}

struct PrintActivity: Equatable {
    enum Phase: Equatable {
        case preparing
        case sending
    }

    var phase: Phase
    var title: String
    var detail: String
    var progress: Double?
}
