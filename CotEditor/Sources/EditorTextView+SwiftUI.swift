import SwiftUI

/// A SwiftUI `NSViewControllerRepresentable` that provides
/// a public interface to `EditorTextView`.
public struct EditorTextViewRepresentable : NSViewControllerRepresentable {
    @Binding var text: String

    public init(text: Binding<String>) {
        self._text = text
    }

    public func makeNSViewController(context: Context) -> EditorTextViewRepresentableController {
        EditorTextViewRepresentableController()
    }

    public func updateNSViewController(_ viewController: EditorTextViewRepresentableController, context: Context) {
        viewController.editorView?.string = self.text
    }

//    internal typealias Coordinator = ViewType.Coordinator
//
//    internal func makeCoordinator() -> Coordinator {
//        view.makeCoordinator()
//    }
}

public final class EditorTextViewRepresentableController : NSViewController {
    let editorView = EditorTextView(coder: NSKeyedArchiver(requiringSecureCoding: false))

    public override func loadView() {
        self.view = editorView!
    }
}
