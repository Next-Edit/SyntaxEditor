import SwiftUI
import CodeEditor

@available(macOS 12.0, *)
struct ContentView : View {
    @State var text: String = "this is some text"

    var body: some View {
        CodeEditor(text: $text)
    }
}
