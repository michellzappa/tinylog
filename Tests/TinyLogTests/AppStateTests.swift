import XCTest
@testable import TinyLog

final class AppStateTests: XCTestCase {
    func testParsedEntriesExtractTimestampLevelAndMessage() {
        let state = AppState()
        state.selectedFile = URL(fileURLWithPath: "/tmp/sample.log")
        state.content = """
        2026-04-03 10:00:00 ERROR failed to start
        Apr  3 10:00:01 WARN cache miss
        [03/Apr/2026:10:00:02 +0000] INFO request handled
        just some text
        """

        let entries = state.parsedEntries

        XCTAssertEqual(entries.count, 4)
        XCTAssertEqual(entries[0].timestamp, "2026-04-03 10:00:00")
        XCTAssertEqual(entries[0].level, .error)
        XCTAssertEqual(entries[0].message, "failed to start")
        XCTAssertEqual(entries[1].level, .warn)
        XCTAssertEqual(entries[2].level, .info)
        XCTAssertEqual(entries[3].level, .unknown)
    }

    func testFiltersAndExportHTMLFollowCurrentSelection() {
        let state = AppState()
        state.selectedFile = URL(fileURLWithPath: "/tmp/sample.log")
        state.content = """
        INFO startup complete
        WARN cache miss
        ERROR request failed
        """
        state.filterLevel = .warn
        state.filterText = "cache"

        XCTAssertEqual(state.filteredEntries.count, 1)
        XCTAssertTrue(state.exportHTML.contains("level-warn"))
        XCTAssertTrue(state.exportHTML.contains("cache miss"))
    }
}
