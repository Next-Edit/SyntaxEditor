import SwiftUI
#if canImport(AppKit)
import CotEditor
#endif

/// A code editor with syntax highlighting
@available(macOS 12.0, iOS 15.0, *)
public struct CodeEditor : SwiftUI.View {
    @SwiftUI.Binding var text: String

    public init(text: SwiftUI.Binding<String>) {
        self._text = text
    }
    
    public var body: some View {
        #if !canImport(AppKit)
        SwiftUI.TextEditor(text: $text) // iOS just gets the plain editor
        #else
        CotEditor.EditorTextWrapperView(text: $text)
        #endif
    }
}
