# App Store Connect — TinyLog

## App Information

- **App Name**: TinyLog
- **Subtitle** (30 chars max): A lightweight log file viewer
- **Bundle ID**: com.tinylog.app
- **SKU**: tinylog-001
- **Primary Language**: English (U.S.)
- **Category**: Developer Tools
- **Secondary Category**: Productivity
- **Content Rights**: Does not contain third-party content
- **Age Rating**: 4+

## Version 1.0.0

### Description (4000 chars max)

TinyLog is a fast, native log file viewer for macOS. Tail a log, filter by level, and scan for errors — without leaving your Mac. No terminal gymnastics. No heavyweight log aggregators. Just a clean window on your log files.

Features:
- Live tail mode — follows new output as it's written, like tail -f
- Filter by log level: ERROR, WARN, INFO, DEBUG, TRACE
- Text search with real-time results
- Dual-pane view: raw log text alongside a structured, filterable table
- Automatic log level detection from common formats
- Timestamp extraction from ISO, syslog, and Apache/Nginx formats
- Sortable columns: line number, timestamp, level, message
- Color-coded log levels — red for errors, orange for warnings, blue for info
- Click any table row to jump to the source line in the editor
- Syntax highlighting for timestamps, IP addresses, quoted strings, and stack traces
- Folder sidebar with directory browsing
- Quick open file finder (Cmd+P)
- Adjustable font size (Cmd+/Cmd-)
- Word wrap toggle (Option+Z)
- Line numbers toggle (Option+L)
- Multiple independent windows
- Light and dark mode — follows your system
- Opens .log, .out, .err, and .txt files directly from Finder

Built entirely with native macOS technologies. No Electron. No web views. Designed for developers who want to read logs, not configure dashboards.

### Keywords (100 chars max, comma-separated)

log,viewer,tail,filter,debug,error,developer,syslog,monitoring,text

### What's New (Version 1.0.0)

Initial release.

### Promotional Text (170 chars max, can be updated without review)

A fast, native log viewer for macOS. Tail files, filter by level, scan for errors. No terminal, no log aggregators. Just your logs, right there.

### Support URL

https://github.com/michellzappa/tinylog/issues

### Marketing URL (optional)

https://github.com/michellzappa/tinylog

### Privacy Policy URL (required)

<!-- You need a privacy policy URL even if the app collects no data. -->
<!-- Example: https://michellzappa.github.io/tinylog/privacy -->

TODO: Create a simple privacy policy page stating the app collects no data.

## Privacy Details

- **Data Collection**: None — the app does not collect any data
- **Tracking**: No
- **Data Linked to You**: None
- **Data Not Linked to You**: None

## Screenshots (required)

Mac: At least one screenshot at 2880x1800 or 1600x1000 (16-inch Retina)

Recommended screenshots:
1. Raw log + filtered table side by side
2. Filtered to ERROR level with highlighted rows
3. Dark mode with tail mode active
4. Folder sidebar with multiple log files

## App Icon

- 1024x1024 PNG (generated from AppIcon.icon assets)
- No transparency, no rounded corners (macOS applies the mask automatically)

## Pricing

- **Price**: Free
- **Availability**: All territories

## Notes for Review

TinyLog is a native macOS log file viewer. It reads local files only and does not modify them. It does not connect to any server, collect any data, or require an account. All processing happens on-device.
