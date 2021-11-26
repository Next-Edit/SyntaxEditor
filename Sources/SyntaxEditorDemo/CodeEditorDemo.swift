import SwiftUI

@main
@available(macOS 12.0, *)
struct SyntaxEditorDemo: App {
    init() {
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            TextEditingCommands()
            TextFormattingCommands()
        }
        //.windowStyle(HiddenTitleBarWindowStyle())
    }
}

