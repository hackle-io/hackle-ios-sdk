import Foundation
import WebKit

/// Receives `postMessage` invocations from the web SDK (user mutation · track · commands).
/// Synchronous queries stay on the prompt path (``HackleUIDelegate``).
@MainActor
class HackleScriptMessageHandler: NSObject, WKScriptMessageHandler {

    /// `window.webkit.messageHandlers.hackle`
    static let name = "hackle"

    private let invocator: HackleInvocator

    init(invocator: HackleInvocator) {
        self.invocator = invocator
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let body = message.body as? String else {
            return
        }
        handle(body: body, webView: message.webView)
    }

    func handle(body: String, webView: WKWebView?) {
        guard invocator.isInvocableString(string: body) else {
            return
        }
        Metrics.counter(name: "webview.bridge.message").increment()

        // requestId가 있는 요청(user mutation)만 완료 시그널을 회신한다.
        guard let requestId = body.jsonObject()?["requestId"] as? String else {
            _ = invocator.invoke(string: body)
            return
        }

        invocator.invokeAsync(string: body) { [weak webView] response in
            guard let webView = webView, let response = response else {
                return
            }
            webView.evaluateJavaScript(Self.resolveScript(requestId: requestId, response: response))
        }
    }

    static func resolveScript(requestId: String, response: String) -> String {
        return "window._hackleBridge && window._hackleBridge.resolve(\(requestId.javascriptStringLiteral()), \(response.javascriptStringLiteral()))"
    }
}

/// `WKUserContentController` strongly retains message handlers.
/// The actual handler is owned by the WebView, so it is registered through this weak proxy.
@MainActor
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {

    private weak var handler: (any WKScriptMessageHandler)?

    init(_ handler: any WKScriptMessageHandler) {
        self.handler = handler
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handler?.userContentController(userContentController, didReceive: message)
    }
}
