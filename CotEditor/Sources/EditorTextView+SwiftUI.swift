import SwiftUI

public struct EditorTextWrapperView : View {
    @Binding var text: String

    public init(text: Binding<String>) {
        self._text = text
    }

    public var body: some View {
        EditorTextViewRepresentable(text: $text)
    }
}

/// A SwiftUI `NSViewControllerRepresentable` that provides
/// a public interface to `EditorTextView`.
struct EditorTextViewRepresentable : NSViewControllerRepresentable {
    @Binding var text: String

    //typealias Controller = WindowContentViewController
    //typealias Controller = SplitViewController
    typealias Controller = EditorViewController

    func makeNSViewController(context: Context) -> Controller {
        let cdr = context.coordinator

        let splitController = cdr.editorViewController
        splitController.textViewItem = cdr.textViewItem
        //splitController.navigationBarController = cdr.navigationBarController // TODO: nav bar controller
        splitController.addSplitViewItem(cdr.textViewItem)

        precondition(splitController.textViewItem != nil)
        precondition(splitController.textViewController != nil)
        let tvc = splitController.textViewController!

        tvc.textView = cdr.textView
        precondition(splitController.textView != nil)
        tvc.lineNumberView = cdr.lineNumberView
        tvc.textView!.delegate = tvc

        // manually re-creating storyboard "Editor Text View Controller" ("F5v-F6-xnV")
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .top
        stack.spacing = 0
        stack.detachesHiddenViews = true

        stack.addArrangedSubview(cdr.lineNumberView)

        //stack.addArrangedSubview(cdr.textView!)
        stack.addArrangedSubview(cdr.textScrollView)

        precondition(tvc.isViewLoaded == false)
        tvc.view = stack
        precondition(tvc.isViewLoaded == true)
        precondition(tvc.view is NSStackView)

        let _ = splitController.view // manually load the view; order is important!

        precondition(stack.ancestorShared(with: cdr.lineNumberView) != nil)
        precondition(stack.ancestorShared(with: cdr.textView) != nil)

        precondition(splitController.splitView.ancestorShared(with: stack) != nil)

        return splitController
    }

    func updateNSViewController(_ viewController: Controller, context: Context) {
        precondition(viewController.isViewShown == true)
        if context.coordinator.textStorage.string != self.text {
            context.coordinator.textStorage.replaceCharacters(in: context.coordinator.textStorage.range, with: self.text)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator : NSObject, NSTextDelegate {
        private let delegate = AppDelegate() // needed to register user defaults

        let textStorage = NSTextStorage()
        let textContainer = TextContainer()
        let layoutManager = LayoutManager()

        lazy var textView: EditorTextView = {
            layoutManager.replaceTextStorage(textStorage)

            let etv = EditorTextView(fromCoder: nil, frame: nil, textContainer: textContainer, layoutManager: layoutManager)!
            etv.usesFontPanel = true
            etv.importsGraphics = false
            etv.isRichText = false
            etv.isVerticallyResizable = true
            return etv
        }()

        let editorViewController = EditorViewController()

        lazy var navigationBarController: NavigationBarController = {
            let controller = NavigationBarController()
            controller.textView = self.textView
            controller.view = NSView()
            return controller
        }()
        lazy var navigationBarItem = NSSplitViewItem(viewController: navigationBarController)

        let editorTextViewController = EditorTextViewController()
        lazy var textViewItem = NSSplitViewItem(viewController: editorTextViewController)


        lazy var textScrollView: NSScrollView = {
            let textScroller = NSScrollView()
            textScroller.hasHorizontalScroller = false
            textScroller.hasVerticalScroller = true
            textScroller.documentView = self.textView
            return textScroller
        }()

        lazy var lineNumberView: LineNumberView = {
            let lnv = LineNumberView()
            lnv.textView = self.textScrollView.documentView as! EditorTextView
            return lnv
        }()
        
    }

}

