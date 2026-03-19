import SwiftUI
import AppKit
import TinyKit

// MARK: - FocusedValue key for per-window AppState

struct FocusedAppStateKey: FocusedValueKey {
    typealias Value = AppState
}

extension FocusedValues {
    var appState: AppState? {
        get { self[FocusedAppStateKey.self] }
        set { self[FocusedAppStateKey.self] = newValue }
    }
}

// MARK: - App

@main
struct TinyLogApp: App {
    @NSApplicationDelegateAdaptor(TinyAppDelegate.self) var appDelegate
    @FocusedValue(\.appState) private var activeState

    var body: some Scene {
        WindowGroup(id: "editor") {
            WindowContentView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                NewWindowButton()
            }

            CommandGroup(replacing: .appInfo) {
                Button("About TinyLog") {
                    NSApp.orderFrontStandardAboutPanel()
                }
                Button("Welcome to TinyLog") {
                    NotificationCenter.default.post(name: .showWelcome, object: nil)
                }
            }

            CommandGroup(after: .newItem) {
                OpenFileButton()

                OpenFolderButton()
            }

            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar") {
                    NotificationCenter.default.post(name: .toggleSidebar, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let toggleSidebar = Notification.Name("toggleSidebar")
}

// MARK: - Window Content

struct WindowContentView: View {
    @State private var state = AppState()
    @State private var showWelcome = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        ContentView(state: state, columnVisibility: $columnVisibility)
            .navigationTitle(state.selectedFile?.lastPathComponent ?? "TinyLog")
            .focusedSceneValue(\.appState, state)
            .onAppear {
                if !TinyAppDelegate.pendingFiles.isEmpty {
                    let files = TinyAppDelegate.pendingFiles
                    TinyAppDelegate.pendingFiles.removeAll()
                    openFiles(files)
                } else if WelcomeState.isFirstLaunch {
                    showWelcome = true
                } else {
                    state.restoreLastFolder()
                }

                TinyAppDelegate.onOpenFiles = { [weak state] urls in
                    guard let state else { return }
                    openFilesInState(urls, state: state)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
                withAnimation {
                    columnVisibility = columnVisibility == .detailOnly ? .automatic : .detailOnly
                }
            }
            .welcomeSheet(
                isPresented: $showWelcome,
                appName: "TinyLog",
                subtitle: "A tiny log viewer.",
                features: [
                    (icon: "doc.text.below.ecg", title: "Log Viewer", description: "View and browse log files with syntax highlighting"),
                    (icon: "line.3.horizontal.decrease.circle", title: "Level Filtering", description: "Filter by ERROR, WARN, INFO, DEBUG, or TRACE"),
                    (icon: "paintbrush", title: "Syntax Highlighting", description: "Color-coded log levels, timestamps, and IPs"),
                    (icon: "arrow.down.to.line", title: "Live Tail", description: "Follow log files as they update in real-time"),
                ],
                onOpen: { state.openFolder() },
                onDismiss: { state.restoreLastFolder() }
            )
            .background(WindowCloseGuard(state: state))
    }

    private func openFiles(_ urls: [URL]) {
        openFilesInState(urls, state: state)
    }

    private func openFilesInState(_ urls: [URL], state: AppState) {
        guard let url = urls.first else { return }
        let folder = url.deletingLastPathComponent()
        if state.folderURL != folder {
            state.setFolder(folder)
        }
        state.selectFile(url)
        columnVisibility = .detailOnly
    }
}

// MARK: - Menu Buttons

struct OpenFileButton: View {
    @FocusedValue(\.appState) private var state

    var body: some View {
        Button("Open File\u{2026}") {
            state?.openFile()
        }
        .keyboardShortcut("o", modifiers: .command)
    }
}

struct OpenFolderButton: View {
    @FocusedValue(\.appState) private var state

    var body: some View {
        Button("Open Folder\u{2026}") {
            state?.openFolder()
        }
        .keyboardShortcut("o", modifiers: [.command, .shift])
    }
}

struct NewWindowButton: View {
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Button("New Window") {
            openWindow(id: "editor")
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])
    }
}
