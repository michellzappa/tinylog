import Foundation
import AppKit
import TinyKit

enum LogLevel: String, CaseIterable, Identifiable {
    case error = "ERROR"
    case warn = "WARN"
    case info = "INFO"
    case debug = "DEBUG"
    case trace = "TRACE"
    case unknown = ""

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .error: return "Error"
        case .warn: return "Warn"
        case .info: return "Info"
        case .debug: return "Debug"
        case .trace: return "Trace"
        case .unknown: return "Other"
        }
    }

    var color: NSColor {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        switch self {
        case .error:
            return isDark ? NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
                          : NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        case .warn:
            return isDark ? NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
                          : NSColor(red: 0.8, green: 0.5, blue: 0.0, alpha: 1.0)
        case .info:
            return isDark ? NSColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0)
                          : NSColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
        case .debug:
            return isDark ? NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
                          : NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        case .trace:
            return isDark ? NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                          : NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        case .unknown:
            return .secondaryLabelColor
        }
    }

    /// Detect log level from a line of text.
    static func detect(in line: String) -> LogLevel {
        let upper = line.uppercased()
        // Check for level keywords — match whole-ish words via common delimiters
        if upper.contains("FATAL") || upper.contains("CRITICAL") || upper.contains("ERROR") {
            return .error
        }
        if upper.contains("WARN") {
            return .warn
        }
        if upper.contains("INFO") {
            return .info
        }
        if upper.contains("DEBUG") {
            return .debug
        }
        if upper.contains("TRACE") {
            return .trace
        }
        return .unknown
    }
}

struct LogEntry: Identifiable {
    let id: Int          // line number (0-based)
    let rawLine: String
    let timestamp: String?
    let level: LogLevel
    let message: String
    let lineRange: NSRange
}

@Observable
final class AppState: FileState {
    init() {
        super.init(
            bookmarkKey: "lastFolderBookmarkLog",
            defaultExtension: "log",
            supportedExtensions: ["log", "out", "err", "txt", "text"]
        )
    }

    // MARK: - Spotlight

    private static let spotlightDomain = "com.tinyapps.tinylog.files"

    override func didOpenFile(_ url: URL) {
        SpotlightIndexer.index(file: url, content: content, domainID: Self.spotlightDomain)
    }

    override func didSaveFile(_ url: URL) {
        didOpenFile(url)
    }

    // MARK: - Export

    var exportHTML: String {
        let entries = filteredEntries
        guard !entries.isEmpty else {
            return ExportManager.wrapHTML(body: "<p>No log entries</p>", title: selectedFile?.lastPathComponent ?? "log")
        }
        var body = "<table><thead><tr><th>#</th><th>Timestamp</th><th>Level</th><th>Message</th></tr></thead><tbody>"
        for entry in entries {
            let levelClass: String
            switch entry.level {
            case .error: levelClass = "level-error"
            case .warn: levelClass = "level-warn"
            case .info: levelClass = "level-info"
            case .debug: levelClass = "level-debug"
            case .trace: levelClass = "level-trace"
            case .unknown: levelClass = ""
            }
            let ts = ExportManager.escapeHTML(entry.timestamp ?? "")
            let msg = ExportManager.escapeHTML(entry.message)
            body += "<tr><td>\(entry.id + 1)</td><td>\(ts)</td>"
            body += "<td class=\"\(levelClass)\">\(entry.level == .unknown ? "" : entry.level.rawValue)</td>"
            body += "<td>\(msg)</td></tr>"
        }
        body += "</tbody></table>"
        return ExportManager.wrapHTML(body: body, title: selectedFile?.lastPathComponent ?? "log")
    }

    // Filter state
    var filterLevel: LogLevel? = nil
    var filterText: String = ""
    var isFollowing: Bool = false

    var isLogFile: Bool {
        guard let ext = selectedFile?.pathExtension.lowercased() else { return false }
        return ["log", "out", "err"].contains(ext)
    }

    // Timestamp regex patterns
    private static let isoTimestampPattern = try! NSRegularExpression(
        pattern: #"\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}[.,]?\d*"#
    )
    private static let syslogTimestampPattern = try! NSRegularExpression(
        pattern: #"[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}"#
    )
    private static let bracketTimestampPattern = try! NSRegularExpression(
        pattern: #"\[\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2}[^\]]*\]"#
    )

    /// Parse content into log entries.
    var parsedEntries: [LogEntry] {
        let lines = content.components(separatedBy: "\n")
        let ns = content as NSString
        var entries: [LogEntry] = []
        var currentOffset = 0

        for (index, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: currentOffset, length: lineLength)

            if !line.isEmpty {
                let timestamp = extractTimestamp(from: line)
                let level = LogLevel.detect(in: line)
                let message = extractMessage(from: line, timestamp: timestamp)

                entries.append(LogEntry(
                    id: index,
                    rawLine: line,
                    timestamp: timestamp,
                    level: level,
                    message: message,
                    lineRange: lineRange
                ))
            }

            currentOffset += lineLength + 1 // +1 for newline
        }
        return entries
    }

    /// Apply level and text filters.
    var filteredEntries: [LogEntry] {
        parsedEntries.filter { entry in
            if let level = filterLevel, entry.level != level {
                return false
            }
            if !filterText.isEmpty {
                return entry.rawLine.localizedCaseInsensitiveContains(filterText)
            }
            return true
        }
    }

    private func extractTimestamp(from line: String) -> String? {
        let nsLine = line as NSString
        let range = NSRange(location: 0, length: nsLine.length)

        // Try ISO timestamps first
        if let match = Self.isoTimestampPattern.firstMatch(in: line, range: range) {
            return nsLine.substring(with: match.range)
        }
        // Try syslog timestamps
        if let match = Self.syslogTimestampPattern.firstMatch(in: line, range: range) {
            return nsLine.substring(with: match.range)
        }
        // Try bracket timestamps (Apache/nginx)
        if let match = Self.bracketTimestampPattern.firstMatch(in: line, range: range) {
            return nsLine.substring(with: match.range)
        }
        return nil
    }

    private func extractMessage(from line: String, timestamp: String?) -> String {
        var msg = line
        // Strip timestamp prefix if found
        if let ts = timestamp, let range = line.range(of: ts) {
            msg = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        // Strip level keyword
        let levels = ["FATAL", "CRITICAL", "ERROR", "WARNING", "WARN", "INFO", "DEBUG", "TRACE"]
        for level in levels {
            if let range = msg.range(of: level, options: .caseInsensitive) {
                // Remove the level and surrounding brackets/delimiters
                let before = msg[msg.startIndex..<range.lowerBound]
                let after = msg[range.upperBound...]
                msg = (before.trimmingCharacters(in: CharacterSet(charactersIn: " []-:|")) + " " +
                       after.trimmingCharacters(in: CharacterSet(charactersIn: " []-:|")))
                    .trimmingCharacters(in: .whitespaces)
                break
            }
        }
        return msg
    }
}
