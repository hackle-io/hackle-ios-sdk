import Foundation
import WebKit

class HackleUIDelegate: NSObject, WKUIDelegate {

    private let invocator: HackleInvocator
    private let uiDelegate: WKUIDelegate?

    init(invocator: HackleInvocator, uiDelegate: WKUIDelegate? = nil) {
        self.invocator = invocator
        self.uiDelegate = uiDelegate
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let processable = invocator.isInvocableString(string: prompt)
        if (processable) {
            invocator.invoke(string: prompt, completionHandler: completionHandler)
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
