
import WebKit

/// The ``DescopeFlowHook`` class allows implementing hooks that customize how the flow
/// webpage looks or behaves, usually by adding CSS, running JavaScript code, or configuring
/// the scroll view or web view.
///
/// You can use hooks by setting the flow's `hooks` array. For example, these hooks will
/// override the flow to have a transparent background and set margins on the body element.
///
/// ```swift
/// flow.hooks = [
///     .setTransparentBody,
///     .addStyles(selector: "body", rules: ["margin: 16px"]),
/// ]
/// ```
///
/// Alterntively, create custom hooks in a ``DescopeFlowHook`` extension to have them all
/// in one place:
///
/// ```swift
/// func showFlow() {
///     let flow = DescopeFlow(url: "https://example.com/myflow")
///     flow.hooks = [.setMaxWidth, .removeFooter, .hideScrollBar]
///     flowView.start(flow: flow)
/// }
///
/// // elsewhere
///
/// extension DescopeFlowHook {
///     static let setMaxWidth = addStyles(selector: ".login-container", rules: ["max-width: 250px"])
///
///     static let removeFooter = runJavaScript(on: .ready, code: """
///         const footer = document.querySelector('#footer')
///         footer?.remove()
///     """)
///
///     static let hideScrollBar = setupScrollView { scrollView in
///         scrollView.showsVerticalScrollIndicator = false
///     }
/// }
/// ```
///
/// You can also implement your own hooks by subclassing ``DescopeFlowHook`` and
/// overriding the ``execute(event:coordinator:)`` method.
@MainActor
open class DescopeFlowHook {
    
    /// The hook event determines when a hook is executed.
    public enum Event: String {
        /// The hook is executed when the flow is started with `start(flow:)`.
        ///
        /// - Note: The flow is not loaded and the `document` element isn't available
        ///     at this point, so this event is not appropriate for making changes to
        ///     the flow page itself.
        case started

        /// The hook is executed when the flow page begins loading.
        ///
        /// - Note: The flow is not loaded and the `document` element isn't available
        ///     at this point, so this event is not appropriate for making changes to
        ///     the flow page itself.
        case loading

        /// The hook is executed when the `document` element is available in the page.
        case loaded

        /// The hook is executed when the flow page is fully loaded and ready to be displayed.
        case ready

        /// The hook is executed when the underlying `WKWebView` that's displaying changes
        /// its layout, i.e., when the value of its `frame` property changes.
        ///
        /// - Important: This event is experimental. It might be called both before
        ///     and after the flow is loaded or ready, so your `execute` method should
        ///     probably check the coordinator's `state` property. It's recommended to
        ///     test well any hook that uses it.
        case layout
    }

    /// When the hook should be executed.
    public let events: Set<Event>

    /// Creates a new ``DescopeFlowHook`` object.
    ///
    /// - Parameter events: A set of events for which the hook will be executed.
    public init(events: Set<Event>) {
        self.events = events
    }
    
    /// Override this method to implement your hook.
    ///
    /// This method is called by the ``DescopeFlowCoordinator`` when one of the events in
    /// the ``events`` set takes place. If the set has more than one member you can check
    /// the `event` parameter and take different actions depending on the specific event.
    ///
    /// The default implementation of this method does nothing.
    ///
    /// - Parameters:
    ///   - event: The event that took place.
    ///   - coordinator: The ``DescopeFlowCoordinator`` that's running the flow.
    open func execute(event: Event, coordinator: DescopeFlowCoordinator) {
    }

    /// The list of default hooks.
    ///
    /// These hooks are always executed, but you can override them by adding the
    /// counterpart hook to the ``DescopeFlow/hooks`` array.
    static let defaults: [DescopeFlowHook] = [
        .disableZoom,
        .disableTouchCallouts,
        .disableTextSelection,
        .disableInputAccessoryView,
    ]
}

/// Basic hooks for customizing the behavior of the flow.
extension DescopeFlowHook {

    /// Creates a hook that will add the specified CSS rules when executed.
    ///
    /// ```swift
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    /// flow.hooks = [
    ///     .addStyles(selector: ".login-container", rules: [
    ///         "max-width: 250px",
    ///         "box-shadow: none",
    ///     ]),
    /// ]
    /// ```
    ///
    /// - Parameters:
    ///   - event: When the hook should be executed, the default value is `.loaded`.
    ///   - selector: The CSS selector, e.g., `"body"` or `"html, .container"`.
    ///   - rules: The CSS rules, e.g., `"background-color: black"`.
    ///
    /// - Returns: A ``DescopeFlowHook`` object that can be added to the ``DescopeFlow/hooks`` array.
    public static func addStyles(on event: Event = .loaded, selector: String, rules: [String]) -> DescopeFlowHook {
        return AddStylesHook(event: event, css: """
            \(selector) {
                \(rules.map { $0 + ";" }.joined(separator: "\n"))
            }
        """)
    }

    /// Creates a hook that will add the specified raw CSS when executed.
    ///
    /// ```swift
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    /// flow.hooks = [ .addStyles(css: "body { margin: 16px; }") ]
    /// ```
    ///
    /// - Parameters:
    ///   - event: When the hook should be executed, the default value is `.loaded`.
    ///   - css: The raw CSS to add, e.g., `".footer { display: none; }"`.
    ///
    /// - Returns: A ``DescopeFlowHook`` object that can be added to the ``DescopeFlow/hooks`` array.
    public static func addStyles(on event: Event = .loaded, css: String) -> DescopeFlowHook {
        return AddStylesHook(event: event, css: css)
    }
    
    /// Creates a hook that will run the specified JavaScript code when executed.
    ///
    /// The code is implicitly wrapped in an immediately invoked function expression, so you
    /// can safely declare variables and not worry about polluting the global namespace.
    ///
    /// ```swift
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    /// flow.hooks = [
    ///     .runJavaScript(on: .ready, code: """
    ///         const footer = document.querySelector('#footer')
    ///         footer?.remove()
    ///     """),
    /// ]
    /// ```
    ///
    /// You can call the various `console` functions and in `debug` builds the log messages
    /// are redirected to the ``DescopeLogger`` if you've configured one.
    ///
    /// ```swift
    /// Descope.setup(projectId: "...") { config in
    ///     config.logger = DescopeLogger()
    /// }
    ///
    /// // elsewhere
    ///
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    /// flow.hooks = [ .runJavaScript("console.log(navigator.userAgent)") ]
    /// ```
    ///
    /// - Parameters:
    ///   - event: When the hook should be executed, the default value is `.loaded`.
    ///   - code: The JavaScript code to run, e.g., `"console.log('Hello world')"`.
    ///
    /// - Returns: A ``DescopeFlowHook`` object that can be added to the ``DescopeFlow/hooks`` array.
    public static func runJavaScript(on event: Event = .loaded, code: String) -> DescopeFlowHook {
        return RunJavaScriptHook(event: event, code: code)
    }

    #if os(iOS)
    /// Creates a hook that will run the provided closure when the flow is started
    /// on the `UIScrollView` used to display it.
    ///
    /// You can use this function to customize the scrolling behavior of the flow. For example:
    ///
    /// ```swift
    /// func showFlow() {
    ///     let flow = DescopeFlow(url: "https://example.com/myflow")
    ///     flow.hooks = [ .disableScrolling ]
    ///     flowView.start(flow: flow)
    /// }
    ///
    /// // elsewhere
    ///
    /// extension DescopeFlowHook {
    ///     static let disableScrolling = setupScrollView { scrollView in
    ///         scrollView.isScrollEnabled = false
    ///         scrollView.showsVerticalScrollIndicator = false
    ///         scrollView.showsHorizontalScrollIndicator = false
    ///         scrollView.contentInsetAdjustmentBehavior = .never
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter closure: A closure that receives the `UIScrollView` instance as its only parameter.
    ///
    /// - Returns: A ``DescopeFlowHook`` object that can be added to the ``DescopeFlow/hooks`` array.
    public static func setupScrollView(_ closure: @escaping (UIScrollView) -> Void) -> DescopeFlowHook {
        return SetupSubviewHook(getter: { $0.webView?.scrollView }, closure: closure)
    }
    #endif

    /// Creates a hook that will run the provided closure when the flow is started
    /// on the `WKWebView` used to display it.
    ///
    /// - Parameter closure: A closure that receives the `WKWebView` instance as its only parameter.
    ///
    /// - Returns: A ``DescopeFlowHook`` object that can be added to the ``DescopeFlow/hooks`` array.
    public static func setupWebView(_ closure: @escaping (WKWebView) -> Void) -> DescopeFlowHook {
        return SetupSubviewHook(getter: { $0.webView }, closure: closure)
    }
}

/// Default hooks that are automatically applied and that configure the flow to behave
/// in a manner that is more consistent with native controls.
extension DescopeFlowHook {

    /// Disables long press interactions on page elements.
    ///
    /// This hook is always run automatically when the flow is loaded, so there's
    /// usually no need to use it in application code.
    public static let disableTouchCallouts = addStyles(selector: "*", rules: ["-webkit-touch-callout: none"])

    /// Enables long press interactions on page elements.
    ///
    /// Add this hook if you want to override the default behavior and enable long press interactions.
    public static let enableTouchCallouts = addStyles(selector: "*", rules: ["-webkit-touch-callout: default"])

    /// Disables text selection in page elements such as labels and buttons.
    ///
    /// This hook is always run automatically when the flow is loaded, so there's
    /// usually no need to use it in application code.
    public static let disableTextSelection = addStyles(selector: "*", rules: ["-webkit-user-select: none"])

    /// Enables text selection in page elements such as labels and buttons.
    ///
    /// Add this hook if you want to override the default behavior and allow text selection.
    public static let enableTextSelection = addStyles(selector: "*", rules: ["-webkit-user-select: auto"])

    /// Disables two finger and double tap zoom gestures.
    ///
    /// This hook is always run automatically when the flow is loaded, so there's
    /// usually no need to use it in application code.
    public static let disableZoom = setViewport("width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no")

    /// Enables two finger and double tap zoom gestures.
    ///
    /// Add this hook if you want to override the default behavior and enable zoom gestures.
    public static let enableZoom = setViewport("width=device-width, initial-scale=1")

    /// Disables the input accessory view that's displayed above the on-screen keyboard.
    ///
    /// This is the default behavior, so there's usually no need to use this hook in application code.
    public static let disableInputAccessoryView = setInputAccessoryView(enabled: false)

    /// Enables the input accessory view that's displayed above the on-screen keyboard.
    ///
    /// Add this hook if you want to override the default behavior and show the input accessory view.
    ///
    /// - Note: This hook only works when running on iOS and when using the default webView
    ///     instance in a ``DescopeFlowView``.
    public static let enableInputAccessoryView = setInputAccessoryView(enabled: true)
}

/// Hooks for overriding the flow background color.
extension DescopeFlowHook {

    /// Creates a hook that will make the flow page have a transparent background.
    ///
    /// You can use this hook when you prefer showing the app's view hierarchy as the
    /// flow background, instead of whatever is defined in the page itself.
    ///
    /// ```swift
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    /// flow.hooks = [ .setTransparentBody ]
    /// flowView.start(flow: flow)
    ///
    /// containerView.isOpaque = false
    /// containerView.backgroundColor = .clear
    /// containerView.addSubview(flowView)
    /// ```
    ///
    /// - Returns: A ``DescopeFlowHook`` object that can be added to the ``DescopeFlow/hooks`` array.
    public static let setTransparentBody = setBackgroundColor(selector: "body", color: .clear)

    /// Creates a hook that will override an element's background color.
    ///
    /// ```swift
    /// let flow = DescopeFlow(url: "https://example.com/myflow")
    /// flow.hooks = [
    ///     .setBackgroundColor(selector: "body", color: .secondarySystemBackground),
    /// ]
    /// ```
    ///
    /// - Parameters:
    ///   - selector: The CSS selector.
    ///   - color: The color to use for the background.
    ///
    /// - Returns: A ``DescopeFlowHook`` object that can be added to the ``DescopeFlow/hooks`` array.
    public static func setBackgroundColor(selector: String, color: PlatformColor) -> DescopeFlowHook {
        return BackgroundColorHook(selector: selector, color: color)
    }

    #if os(iOS)
    public typealias PlatformColor = UIColor
    #else
    public typealias PlatformColor = NSColor
    #endif
}

// Internal

private class AddStylesHook: DescopeFlowHook {
    let css: String

    init(event: Event, css: String) {
        self.css = css
        super.init(events: [event])
    }

    override func execute(event: Event, coordinator: DescopeFlowCoordinator) {
        coordinator.addStyles(css)
    }
}

private class RunJavaScriptHook: DescopeFlowHook {
    let code: String

    init(event: Event, code: String) {
        self.code = code
        super.init(events: [event])
    }

    override func execute(event: Event, coordinator: DescopeFlowCoordinator) {
        coordinator.runJavaScript(code)
    }
}

private class SetupSubviewHook<T>: DescopeFlowHook {
    let getter: (DescopeFlowCoordinator) -> T?
    let closure: (T) -> Void

    init(getter: @escaping (DescopeFlowCoordinator) -> T?, closure: @escaping (T) -> Void) {
        self.getter = getter
        self.closure = closure
        super.init(events: [.started])
    }

    override func execute(event: Event, coordinator: DescopeFlowCoordinator) {
        guard let object = getter(coordinator) else { return }
        closure(object)
    }
}

private extension DescopeFlowHook {
    static func setViewport(_ value: String) -> DescopeFlowHook {
        return RunJavaScriptHook(event: .loaded, code: """
            const content = \(value.javaScriptLiteralString())
            let viewport = document.head.querySelector('meta[name=viewport]')
            if (viewport) {
                viewport.content = content 
            } else {
                viewport = document.createElement('meta')
                viewport.name = 'viewport'
                viewport.content = content
                document.head.appendChild(viewport)
            }
        """)
    }

    static func setInputAccessoryView(enabled: Bool) -> DescopeFlowHook {
        return setupWebView { webView in
            #if os(iOS)
            guard let customWebView = webView as? DescopeCustomWebView else { return }
            customWebView.showsInputAccessoryView = false
            #endif
        }
    }
}

private class BackgroundColorHook: DescopeFlowHook {
    let selector: String
    let color: PlatformColor

    init(selector: String, color: PlatformColor) {
        self.selector = selector
        self.color = color
        super.init(events: [.started, .loaded])
    }

    override func execute(event: Event, coordinator: DescopeFlowCoordinator) {
        if event == .started {
            guard #available(iOS 15.0, *) else { return }
            coordinator.webView?.underPageBackgroundColor = color
        } else if event == .loaded {
            coordinator.addStyles("\(selector) { background-color: \(colorStringValue); }")
        }
    }

    private var colorStringValue: String {
        var (red, green, blue, alpha): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        guard alpha > 0 else { return "transparent" }
        return "rgba(\(round(red * 255)), \(round(green * 255)), \(round(blue * 255)), \(alpha))"
    }
}
