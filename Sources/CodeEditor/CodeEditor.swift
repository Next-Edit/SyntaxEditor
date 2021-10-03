import SwiftUI
#if canImport(AppKit)
import CotEditor
#endif

/// A code editor with syntax highlighting
@available(macOS 12.0, iOS 15.0, *)
public struct CodeEditor : View {
    @Binding var text: String

    public init(text: Binding<String>) {
        self._text = text
    }
    
    public var body: some View {
        #if !canImport(AppKit)
        TextEditor(text: $text) // iOS just gets the plain editor
        #else
        EditorTextWrapperView(text: $text)
        #endif
    }
}
