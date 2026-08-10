import Foundation
import WebKit

class MockFrameInfo: WKFrameInfo {
    // On the iOS 26.2 SDK, `-[WKFrameInfo dealloc]` crashes (CFRetain on an internal
    // handle that WebKit's private designated initializer would normally populate) for
    // instances created via a bare `super.init()`. Retaining every instance for the
    // lifetime of the test process avoids ever running that dealloc path.
    private static var retained: [MockFrameInfo] = []

    private let _isMainFrame: Bool

    init(isMainFrame: Bool) {
        self._isMainFrame = isMainFrame
        super.init()
        MockFrameInfo.retained.append(self)
    }

    override var isMainFrame: Bool { _isMainFrame }
}

class MockScriptMessage: WKScriptMessage {
    private let _body: Any
    private let _frameInfo: WKFrameInfo
    private weak var _webView: WKWebView?

    init(body: Any, frameInfo: WKFrameInfo = MockFrameInfo(isMainFrame: true), webView: WKWebView? = nil) {
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
