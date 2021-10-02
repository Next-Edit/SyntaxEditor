import SwiftUI
#if !canImport(AppKit)
import CotEditor
#endif

/// A code editor with syntax highlighting
public struct CodeEditor : View {
    @Binding var text: String

    public var body: some View {
        #if !canImport(AppKit)
        TextEditor(text: $text) // iOS just gets the plain editor
        #else
        #warning("TODO: integrate with CotEditor here")
        TextEditor(text: $text)
        #endif
    }
}
