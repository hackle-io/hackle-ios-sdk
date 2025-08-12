import Foundation
import WebKit

class HackleUIDelegate: NSObject, WKUIDelegate {

    private let bridge: HackleAppBridge
    private let uiDelegate: WKUIDelegate?

    init(hackleAppCore: HackleAppCoreProtocol, uiDelegate: WKUIDelegate? = nil) {
        self.bridge = HackleBridge(hackleAppCore: hackleAppCore)
        self.uiDelegate = uiDelegate
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let processable = bridge.isInvocableString(string: prompt)
        if (processable) {
            bridge.invoke(string: prompt, completionHandler: completionHandler)
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
