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

/// Routes messages from a shared user content controller to the handler for the originating WebView.
@MainActor
final class HackleScriptMessageRouter: NSObject, WKScriptMessageHandler {
    private var handlers: [ObjectIdentifier: WeakHandler] = [:]

    func register(webView: WKWebView, handler: HackleScriptMessageHandler) {
        handlers = handlers.filter { $0.value.handler != nil }
        handlers[ObjectIdentifier(webView)] = WeakHandler(handler)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handlers = handlers.filter { $0.value.handler != nil }
        guard let webView = message.webView,
              let handler = handlers[ObjectIdentifier(webView)]?.handler
        else {
            return
        }
        handler.userContentController(userContentController, didReceive: message)
    }

    private final class WeakHandler {
        weak var handler: HackleScriptMessageHandler?

        init(_ handler: HackleScriptMessageHandler) {
            self.handler = handler
        }
    }
}
