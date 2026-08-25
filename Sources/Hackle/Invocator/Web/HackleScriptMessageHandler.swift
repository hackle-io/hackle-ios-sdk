import Foundation
import WebKit

/// Receives `postMessage` invocations from the web SDK (user mutation · track · commands),
/// dispatched by ``HackleScriptMessageDispatcher``.
/// Synchronous queries stay on the prompt path (``HackleUIDelegate``).
/// Every message channel request must carry a `messageId`; requests without one are not handled.
@MainActor
class HackleScriptMessageHandler: NSObject {

    /// `window.webkit.messageHandlers.hackle`
    nonisolated static let name = "hackle"

    private let invocator: HackleInvocator

    init(invocator: HackleInvocator) {
        self.invocator = invocator
    }

    func didReceive(_ message: WKScriptMessage) {
        guard let body = message.body as? String else {
            return
        }
        handle(body: body, webView: message.webView)
    }

    func handle(body: String, webView: WKWebView?) {
        guard invocator.isInvocableString(string: body) else {
            return
        }

        guard let messageId = InvocationRequest.messageId(string: body) else {
            Log.error("Invalid invocation format (missing: messageId). [message=\(body)]")
            return
        }

        invocator.invokeAsync(string: body) { [weak webView] response in
            guard let webView = webView, let response = response else {
                Log.debug("Skipped bridge resolve. [messageId=\(messageId), webViewReleased=\(webView == nil)]")
                return
            }
            webView.evaluateJavaScript(Self.resolveScript(messageId: messageId, response: response))
        }
    }

    static func resolveScript(messageId: String, response: String) -> String {
        return "window._hackleBridge && window._hackleBridge.resolveMessage(\(messageId.javascriptStringLiteral()), \(response.javascriptStringLiteral()))"
    }
}

/// Dispatches messages from a shared user content controller to the handler of the originating WebView.
/// Each WebView owns its handler, so a single stateless dispatcher serves every WebView on the controller.
@MainActor
final class HackleScriptMessageDispatcher: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let handler = message.webView?._messageHandler else {
            Log.debug("Bridge is not applied to the WebView that sent the message.")
            return
        }
        handler.didReceive(message)
    }
}
