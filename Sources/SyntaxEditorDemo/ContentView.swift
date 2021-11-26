import SwiftUI
import SyntaxEditor

@available(macOS 12.0, *)
struct ContentView : View {
    @State var text: String = "this is some text"

    var body: some View {
        SyntaxEditor(text: $text)
    }
}
