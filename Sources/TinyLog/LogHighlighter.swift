import AppKit
import TinyKit

/// Syntax highlighter for log files.
/// Colors timestamps, log levels, IP addresses, quoted strings, and stack traces.
final class LogHighlighter: SyntaxHighlighting {
    var baseFont: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    private var isDark: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private var timestampColor: NSColor {
        isDark ? NSColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)
               : NSColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
    }

    private var errorColor: NSColor {
        isDark ? NSColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
               : NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
    }

    private var warnColor: NSColor {
        isDark ? NSColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
               : NSColor(red: 0.8, green: 0.5, blue: 0.0, alpha: 1.0)
    }

    private var infoColor: NSColor {
        isDark ? NSColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0)
               : NSColor(red: 0.0, green: 0.3, blue: 0.7, alpha: 1.0)
    }

    private var debugColor: NSColor {
        isDark ? NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
               : NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    }

    private var stringColor: NSColor {
        isDark ? NSColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 1.0)
               : NSColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1.0)
    }

    private var numberColor: NSColor {
        isDark ? NSColor(red: 0.95, green: 0.7, blue: 0.4, alpha: 1.0)
               : NSColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)
    }

    private var ipColor: NSColor {
        isDark ? NSColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0)
               : NSColor(red: 0.3, green: 0.4, blue: 0.6, alpha: 1.0)
    }

    private var stackTraceColor: NSColor {
        isDark ? NSColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1.0)
               : NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    }

    // Precompiled regex patterns
    private static let timestampRegex = try! NSRegularExpression(
        pattern: #"\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}[.,]?\d*|[A-Z][a-z]{2}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}|\[\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2}[^\]]*\]"#
    )
    private static let levelRegex = try! NSRegularExpression(
        pattern: #"\b(FATAL|CRITICAL|ERROR|WARN(?:ING)?|INFO|DEBUG|TRACE)\b"#,
        options: .caseInsensitive
    )
    private static let ipRegex = try! NSRegularExpression(
        pattern: #"\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?::\d+)?\b"#
    )
    private static let stackTraceRegex = try! NSRegularExpression(
        pattern: #"^\s+(at\s+|Caused by:|\.{3}\s+\d+\s+more)"#,
        options: .anchorsMatchLines
    )

    func highlight(_ textStorage: NSTextStorage) {
        let source = textStorage.string
        let fullRange = NSRange(location: 0, length: (source as NSString).length)
        guard fullRange.length > 0 else { return }

        textStorage.beginEditing()

        // Reset to base
        textStorage.addAttributes([
            .font: baseFont,
            .foregroundColor: NSColor.textColor,
            .backgroundColor: NSColor.clear,
        ], range: fullRange)

        // Color timestamps
        for match in Self.timestampRegex.matches(in: source, range: fullRange) {
            textStorage.addAttribute(.foregroundColor, value: timestampColor, range: match.range)
        }

        // Color log levels
        for match in Self.levelRegex.matches(in: source, range: fullRange) {
            let keyword = (source as NSString).substring(with: match.range).uppercased()
            let color: NSColor
            let bold: NSFont

            switch keyword {
            case "FATAL", "CRITICAL", "ERROR":
                color = errorColor
                bold = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold)
            case "WARN", "WARNING":
                color = warnColor
                bold = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .medium)
            case "INFO":
                color = infoColor
                bold = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .medium)
            case "DEBUG":
                color = debugColor
                bold = baseFont
            case "TRACE":
                color = debugColor
                bold = baseFont
            default:
                color = NSColor.textColor
                bold = baseFont
            }

            textStorage.addAttributes([
                .foregroundColor: color,
                .font: bold,
            ], range: match.range)
        }

        // Color IP addresses
        for match in Self.ipRegex.matches(in: source, range: fullRange) {
            textStorage.addAttribute(.foregroundColor, value: ipColor, range: match.range)
        }

        // Color stack trace lines
        for match in Self.stackTraceRegex.matches(in: source, range: fullRange) {
            textStorage.addAttributes([
                .foregroundColor: stackTraceColor,
                .font: NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .light),
            ], range: match.range)
        }

        // Color quoted strings
        let ns = source as NSString
        let length = ns.length
        var i = 0
        while i < length {
            let ch = ns.character(at: i)
            if ch == 0x22 { // "
                let start = i
                i += 1
                while i < length {
                    let c = ns.character(at: i)
                    if c == 0x5C { i += 2; continue } // backslash escape
                    if c == 0x22 { i += 1; break }    // closing "
                    if c == 0x0A { break }             // newline — unterminated
                    i += 1
                }
                let strRange = NSRange(location: start, length: i - start)
                textStorage.addAttribute(.foregroundColor, value: stringColor, range: strRange)
            } else {
                i += 1
            }
        }

        textStorage.endEditing()
    }
}
