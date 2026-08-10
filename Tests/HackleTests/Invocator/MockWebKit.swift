import Foundation
import WebKit

class MockFrameInfo: WKFrameInfo {
    // On the iOS 26.2 SDK, `-[WKFrameInfo dealloc]` crashes (CFRetain on an internal
    // handle that WebKit's private designated initializer would normally populate) for
    // instances created via a bare `super.init()`. Sharing two fixed, never-deallocated
    // instances (rather than leaking one per call) avoids that dealloc path without
    // introducing unsynchronized, unbounded process-global mutable state.
    static let mainFrame = MockFrameInfo(isMainFrame: true)
    static let subFrame = MockFrameInfo(isMainFrame: false)

    private let _isMainFrame: Bool

    init(isMainFrame: Bool) {
        self._isMainFrame = isMainFrame
        super.init()
    }

    override var isMainFrame: Bool { _isMainFrame }
}

class MockScriptMessage: WKScriptMessage {
    private let _body: Any
    private let _frameInfo: WKFrameInfo
    private weak var _webView: WKWebView?

    init(body: Any, frameInfo: WKFrameInfo = MockFrameInfo.mainFrame, webView: WKWebView? = nil) {
        self._body = body
        self._frameInfo = frameInfo
        self._webView = webView
        super.init()
    }

    override var name: String { "hackle" }
    override var body: Any { _body }
    override var frameInfo: WKFrameInfo { _frameInfo }
    override var webView: WKWebView? { _webView }
}

class MockWebView: WKWebView {
    var evaluatedScripts: [String] = []

    override func evaluateJavaScript(_ javaScriptString: String, completionHandler: (@MainActor @Sendable (Any?, (any Error)?) -> Void)? = nil) {
        evaluatedScripts.append(javaScriptString)
    }
}
