import SwiftUI
import AppKit

/// Filter bar + table view showing parsed and filtered log entries.
struct LogPreviewView: View {
    @Bindable var state: AppState
    @Binding var jumpToRange: NSRange?

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundStyle(.secondary)

                Picker("Level", selection: $state.filterLevel) {
                    Text("All").tag(LogLevel?.none)
                    Divider()
                    ForEach(LogLevel.allCases.filter { $0 != .unknown }) { level in
                        Text(level.displayName).tag(LogLevel?.some(level))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 90)

                TextField("Filter...", text: $state.filterText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))

                Text("\(state.filteredEntries.count) of \(state.parsedEntries.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)

                if state.isFollowing {
                    Image(systemName: "arrow.down.to.line")
                        .foregroundStyle(.green)
                        .font(.system(size: 11))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)

            Divider()

            // Log entries table
            LogTableView(
                entries: state.filteredEntries,
                isFollowing: state.isFollowing
            ) { entry in
                jumpToRange = entry.lineRange
            }
        }
    }
}

/// NSTableView wrapper showing log entries.
struct LogTableView: NSViewRepresentable {
    let entries: [LogEntry]
    let isFollowing: Bool
    var onRowTap: ((LogEntry) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnReordering = false
        tableView.allowsColumnResizing = true
        tableView.allowsColumnSelection = false
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.intercellSpacing = NSSize(width: 6, height: 2)
        tableView.rowHeight = 18
        tableView.headerView = NSTableHeaderView()

        // Line number column
        let lineCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("line"))
        lineCol.title = "#"
        lineCol.minWidth = 40
        lineCol.width = 50
        lineCol.maxWidth = 70
        tableView.addTableColumn(lineCol)

        // Timestamp column
        let tsCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("timestamp"))
        tsCol.title = "Timestamp"
        tsCol.minWidth = 80
        tsCol.width = 160
        tsCol.maxWidth = 250
        tableView.addTableColumn(tsCol)

        // Level column
        let levelCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("level"))
        levelCol.title = "Level"
        levelCol.minWidth = 50
        levelCol.width = 60
        levelCol.maxWidth = 80
        tableView.addTableColumn(levelCol)

        // Message column
        let msgCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("message"))
        msgCol.title = "Message"
        msgCol.minWidth = 200
        msgCol.width = 500
        tableView.addTableColumn(msgCol)

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false

        context.coordinator.tableView = tableView
        context.coordinator.onRowTap = onRowTap
        context.coordinator.entries = entries

        tableView.target = context.coordinator
        tableView.action = #selector(Coordinator.tableClicked(_:))

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.entries = entries
        context.coordinator.onRowTap = onRowTap
        context.coordinator.tableView?.reloadData()

        // Auto-scroll to bottom when following
        if isFollowing, let tableView = context.coordinator.tableView, entries.count > 0 {
            tableView.scrollRowToVisible(entries.count - 1)
        }
    }

    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var tableView: NSTableView?
        var entries: [LogEntry] = []
        var onRowTap: ((LogEntry) -> Void)?

        func numberOfRows(in tableView: NSTableView) -> Int {
            entries.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn, row < entries.count else { return nil }
            let entry = entries[row]
            let colID = tableColumn.identifier.rawValue

            let cellID = NSUserInterfaceItemIdentifier("logcell_\(colID)")
            let cell: NSTextField
            if let existing = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTextField {
                cell = existing
            } else {
                cell = NSTextField(labelWithString: "")
                cell.identifier = cellID
                cell.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
                cell.lineBreakMode = .byTruncatingTail
                cell.cell?.truncatesLastVisibleLine = true
            }

            switch colID {
            case "line":
                cell.stringValue = "\(entry.id + 1)"
                cell.alignment = .right
                cell.textColor = .tertiaryLabelColor
            case "timestamp":
                cell.stringValue = entry.timestamp ?? ""
                cell.textColor = .secondaryLabelColor
            case "level":
                cell.stringValue = entry.level == .unknown ? "" : entry.level.rawValue
                cell.textColor = entry.level.color
                cell.font = entry.level == .error
                    ? .monospacedSystemFont(ofSize: 11, weight: .bold)
                    : .monospacedSystemFont(ofSize: 11, weight: .medium)
            case "message":
                cell.stringValue = entry.message
                cell.textColor = entry.level == .error ? entry.level.color : .textColor
            default:
                cell.stringValue = ""
            }

            cell.toolTip = entry.rawLine
            return cell
        }

        @objc func tableClicked(_ sender: NSTableView) {
            let row = sender.clickedRow
            guard row >= 0, row < entries.count else { return }
            onRowTap?(entries[row])
        }
    }
}
