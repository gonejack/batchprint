import CUPS
import Foundation

/// A printer queue known to the local CUPS scheduler.
struct DiscoveredPrinter: Identifiable, Equatable {
    /// Queue name accepted by `lp -d`.
    let queueName: String
    /// Friendly name shown in the interface.
    let displayName: String
    let isDefault: Bool

    var id: String { queueName }
}

enum PrinterCatalog {
    /// Lists configured CUPS queues.
    ///
    /// `cupsGetDests` also returns printers discovered over Bonjour that have
    /// not been added to the system. Those entries do not have a local
    /// `printer-uri-supported` attribute and cannot reliably accept `lp -d`,
    /// so they are filtered out here.
    static func configuredPrinters() -> [DiscoveredPrinter] {
        var destinations: UnsafeMutablePointer<cups_dest_t>?
        let count = cupsGetDests(&destinations)

        guard count > 0, let destinations else { return [] }
        defer { cupsFreeDests(count, destinations) }

        var printers: [DiscoveredPrinter] = []

        for index in 0..<Int(count) {
            let destination = destinations[index]
            let queueName = String(cString: destination.name)

            var displayName = ""
            var hasLocalQueue = false
            var isTemporary = false

            if let options = destination.options {
                for optionIndex in 0..<Int(destination.num_options) {
                    let option = options[optionIndex]
                    guard let name = option.name, let value = option.value else { continue }

                    switch String(cString: name) {
                    case "printer-info":
                        let info = String(cString: value)
                        if !info.isEmpty { displayName = info }
                    case "printer-uri-supported":
                        hasLocalQueue = true
                    case "printer-is-temporary":
                        isTemporary = String(cString: value) == "true"
                    default:
                        break
                    }
                }
            }

            guard hasLocalQueue, !isTemporary else { continue }

            printers.append(
                DiscoveredPrinter(
                    queueName: queueName,
                    displayName: displayName.isEmpty ? queueName : displayName,
                    isDefault: destination.is_default != 0
                )
            )
        }

        return printers.sorted {
            $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
        }
    }
}
