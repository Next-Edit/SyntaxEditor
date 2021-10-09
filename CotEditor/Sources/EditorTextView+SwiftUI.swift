import SwiftUI
import Combine

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

    @Environment(\.undoManager) var undoManager

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

        cdr.textEditingObserver = NotificationCenter.default
            .publisher(for: NSTextStorage.didProcessEditingNotification, object: cdr.textStorage)
            .map { $0.object as! NSTextStorage }
            .map(\.string)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .assign(to: \.text, on: self)

        //            NotificationCenter.default.obser

        //            etv.font = wip(NSFont.systemFont(ofSize: 24))
        //            etv.backgroundColor = wip(NSColor.gray)
        //            etv.showsInvisibles = true
                    // etv.theme = ThemeManager.shared
        //            let tm = ThemeManager.shared
        //            tm.
        //            UserDefaults.standard[.pinsThemeAppearance] = false
        //            UserDefaults.standard[.fontName] = "Menlo"
        //            UserDefaults.standard[.fontSize] = 0

        let themeName = wip("Classic") // ThemeManager.shared.userDefaultSettingName
        if let theme = ThemeManager.shared.setting(name: themeName) {
            tvc.textView?.theme = theme
        }

        // tvc.undoManager = self.undoManager

        let syntaxParser = SyntaxParser(textStorage: context.coordinator.textStorage)
        syntaxParser.style = SyntaxManager.shared.setting(name: UserDefaults.standard[.syntaxStyle]) ?? SyntaxStyle()

        return splitController
    }

    func updateNSViewController(_ viewController: Controller, context: Context) {
        precondition(viewController.isViewShown == true)
        let storage = context.coordinator.textStorage
        if storage.string != self.text {
            storage.replaceCharacters(in: storage.range, with: self.text)
        }

    }

    static func dismantleNSViewController(_ nsViewController: EditorViewController, coordinator: Coordinator) {
        coordinator.textEditingObserver = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator : NSObject, NSTextDelegate {
        private let delegate = AppDelegate() // needed to register user defaults

        let textStorage = NSTextStorage()
        let textContainer = TextContainer()
        let layoutManager = LayoutManager()
        var textEditingObserver: AnyCancellable?

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
            lnv.textView = self.textScrollView.documentView as? EditorTextView
            return lnv
        }()
        
    }

}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }
