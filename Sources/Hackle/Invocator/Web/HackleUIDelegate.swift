import Foundation
import WebKit

@MainActor
class HackleUIDelegate: NSObject, WKUIDelegate {

    private let invocator: HackleInvocator
    private nonisolated(unsafe) weak var uiDelegate: WKUIDelegate?

    init(invocator: HackleInvocator, uiDelegate: WKUIDelegate? = nil) {
        self.invocator = invocator
        self.uiDelegate = uiDelegate
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let delegateCreateWebView = uiDelegate?.webView(
            _:createWebViewWith:for:windowFeatures:
        ) else {
            return nil
        }
        return delegateCreateWebView(webView, configuration, navigationAction, windowFeatures)
    }

    func webViewDidClose(_ webView: WKWebView) {
        uiDelegate?.webViewDidClose?(webView)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable () -> Void
    ) {
        guard let delegateAlert = uiDelegate?.webView(
            _:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:
        ) else {
            completionHandler()
            return
        }
        delegateAlert(webView, message, frame, completionHandler)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        guard let delegateConfirm = uiDelegate?.webView(
            _:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:
        ) else {
            completionHandler(false)
            return
        }
        delegateConfirm(webView, message, frame, completionHandler)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor @Sendable (String?) -> Void
    ) {
        let processable = invocator.isInvocableString(string: prompt)
        if (processable) {
            let result = invocator.invoke(string: prompt)
            completionHandler(result)
        } else {
            guard let uiDelegate = uiDelegate,
                  let delegatePrompt = uiDelegate.webView(_:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)
            else {
                completionHandler(nil)
                return
            }
            delegatePrompt(webView, prompt, defaultText, frame, completionHandler)
        }
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector) {
            return true
        } else {
            return uiDelegate?.responds(to: aSelector) ?? false
        }
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if super.responds(to: aSelector) {
            return self
        } else {
            return uiDelegate
        }
    }
}
