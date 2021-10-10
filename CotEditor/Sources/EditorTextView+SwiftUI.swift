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
    @Environment(\.font) var font
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.locale) var locale

    func makeNSViewController(context: Context) -> EditorViewController {
        context.coordinator.createController(text: $text)
    }

    func updateNSViewController(_ viewController: EditorViewController, context: Context) {
        precondition(viewController.isViewShown == true)
        //viewController.textViewController?.undoManager = self.undoManager
        let storage = context.coordinator.textStorage
        if storage.string != self.text {
            storage.replaceCharacters(in: storage.range, with: self.text)
        }
    }

    static func dismantleNSViewController(_ nsViewController: EditorViewController, coordinator: EditorViewCoordinator) {
        coordinator.textEditingObserver = nil
    }

    func makeCoordinator() -> EditorViewCoordinator {
//        UserDefaults.standard[.fontName] = "Menlo"
//        UserDefaults.standard[.fontSize] = 44
        return EditorViewCoordinator()
    }
}

final class EditorViewCoordinator : NSObject, NSTextDelegate, NSTextStorageDelegate {
    private let delegate = AppDelegate() // needed to register user defaults
    
    lazy var textStorage: NSTextStorage = {
        let storage = NSTextStorage()
        storage.delegate = self
        return storage
    }()

    let textContainer = TextContainer()
    let layoutManager = LayoutManager()
    var textEditingObserver: AnyCancellable?
    
    lazy var syntaxParser: SyntaxParser = {
        let syntaxParser = SyntaxParser(textStorage: self.textStorage)
        return syntaxParser
    }()
    
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
    
    private lazy var outlineParseTask = Debouncer(delay: .seconds(0.4)) { [weak self] in
        self?.syntaxParser.invalidateOutline()
    }

    private var syntaxHighlightProgress: Progress?

    func createController(text: Binding<String>) -> EditorViewController {
        let splitController = self.editorViewController
        splitController.textViewItem = self.textViewItem
        //splitController.navigationBarController = self.navigationBarController // TODO: nav bar controller
        splitController.addSplitViewItem(self.textViewItem)

        precondition(splitController.textViewItem != nil)
        precondition(splitController.textViewController != nil)
        let tvc = splitController.textViewController!

        tvc.textView = self.textView
        precondition(splitController.textView != nil)
        tvc.lineNumberView = self.lineNumberView
        tvc.textView!.delegate = tvc

        // manually re-creating storyboard "Editor Text View Controller" ("F5v-F6-xnV")
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .top
        stack.spacing = 0
        stack.detachesHiddenViews = true

        stack.addArrangedSubview(self.lineNumberView)

        //stack.addArrangedSubview(self.textView!)
        stack.addArrangedSubview(self.textScrollView)

        precondition(tvc.isViewLoaded == false)
        tvc.view = stack
        precondition(tvc.isViewLoaded == true)
        precondition(tvc.view is NSStackView)

        let _ = splitController.view // manually load the view; order is important!

        precondition(stack.ancestorShared(with: self.lineNumberView) != nil)
        precondition(stack.ancestorShared(with: self.textView) != nil)

        precondition(splitController.splitView.ancestorShared(with: stack) != nil)

        //let f = self.font?.monospacedDigit()

        self.textEditingObserver = NotificationCenter.default
            .publisher(for: NSTextStorage.didProcessEditingNotification, object: self.textStorage)
            .compactMap({ $0.object as? NSTextStorage })
            .map(\.string)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            //.assign(to: \.text, on: self)
            .sink(receiveValue: {
                text.wrappedValue = $0
            })

        // NotificationCenter.default.observer
        // etv.font = wip(NSFont.systemFont(ofSize: 24))
        // etv.backgroundColor = wip(NSColor.gray)
        // etv.showsInvisibles = true
        // etv.theme = ThemeManager.shared
        // let tm = ThemeManager.shared
        // tm.
        // UserDefaults.standard[.pinsThemeAppearance] = false

        let themeName = wip("Classic") // ThemeManager.shared.userDefaultSettingName
        if let theme = ThemeManager.shared.setting(name: themeName) {
            tvc.textView?.theme = theme
        }


        // tvc.undoManager = self.undoManager

//        let syntaxParser = SyntaxParser(textStorage: context.coordinator.textStorage)
//        syntaxParser.style = SyntaxManager.shared.setting(name: UserDefaults.standard[.syntaxStyle]) ?? SyntaxStyle()

//        self.syntaxParser.style = SyntaxManager.shared.setting(name: UserDefaults.standard[.syntaxStyle]) ?? SyntaxStyle()
        self.syntaxParser.style = SyntaxManager.shared.setting(name: wip(BundledStyleName.markdown))!


        return splitController
    }

    // MARK: Delegate
    
    /// text was edited (invoked right **before** notifying layout managers)
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard
            editedMask.contains(.editedCharacters),
            self.textView.hasMarkedText() != true
        else { return }

        //self.document?.analyzer.invalidate()
        //self.document?.incompatibleCharacterScanner.invalidate()
        //self.outlineParseTask.schedule()

        // -> Perform in the next run loop to give layoutManagers time to update their values.
        DispatchQueue.main.async { [weak self] in
            self?.invalidateSyntaxHighlight(in: editedRange)
        }
    }


    /// Invalidate the current syntax highlight.
    ///
    /// - Parameter range: The character range to invalidate syntax highlight, or `nil` when entire text is needed to re-highlight.
    private func invalidateSyntaxHighlight(in range: NSRange? = nil) {

        var range = range

        // retry entire syntax highlight if the last highlightAll has not finished yet
        if let progress = self.syntaxHighlightProgress, !progress.isFinished, !progress.isCancelled {
            progress.cancel()
            self.syntaxHighlightProgress = nil
            range = nil
        }

        let parser = self.syntaxParser // else { return assertionFailure() }

        // start parse
        let progress = parser.highlight(around: range)

        // show indicator for a large update
        let threshold = UserDefaults.standard[.showColoringIndicatorTextLength]
        let highlightLength = range?.length ?? self.textStorage.length
        guard threshold > 0, highlightLength > threshold else { return }

        self.syntaxHighlightProgress = progress

        guard progress != nil else { return }

//        self.progressIndicatorAvailabilityObserver = self.$sheetAvailability
//            .filter { $0 }
//            .sink { [weak self] _ in self?.presentSyntaxHighlightProgress() }
    }


}

/// Work-in-Progress marker
@available(*, deprecated, message: "work in progress")
internal func wip<T>(_ value: T) -> T { value }
