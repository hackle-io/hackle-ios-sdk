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
                Log.debug("Skipped bridge resolve. [requestId=\(requestId), webViewReleased=\(webView == nil), hasResponse=\(response != nil)]")
                return
            }
            webView.evaluateJavaScript(Self.resolveScript(requestId: requestId, response: response))
        }
    }

    static func resolveScript(requestId: String, response: String) -> String {
        return "window._hackleBridge && window._hackleBridge.resolve(\(requestId.javascriptStringLiteral()), \(response.javascriptStringLiteral()))"
    }
}

/// Routes messages from a shared user content controller to the handler of the originating WebView.
/// Each WebView owns its handler, so a single stateless router serves every WebView on the controller.
@MainActor
final class HackleScriptMessageRouter: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let handler = message.webView?._messageHandler else {
            Log.debug("Bridge is not applied to the WebView that sent the message.")
            return
        }
        handler.userContentController(userContentController, didReceive: message)
    }
}
