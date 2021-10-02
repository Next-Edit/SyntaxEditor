import SwiftUI
#if canImport(AppKit)
@testable import CotEditor
#endif

/// A code editor with syntax highlighting
public struct CodeEditor : View {
    @Binding var text: String

    public var body: some View {
        #if !canImport(AppKit)
        TextEditor(text: $text) // iOS just gets the plain editor
        #else
        EditorTextViewRepresentable(text: $text)
        #endif
    }
}
