import Foundation
import WebKit

@objc public class HackleUIDelegate : NSObject, WKUIDelegate {
    
    private let uiDelegate: WKUIDelegate?
    
    @objc public init(uiDelegate: WKUIDelegate? = nil) {
        self.uiDelegate = uiDelegate
    }
    
    @objc public func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let processable = Hackle.app()?.isInvocableString(string: prompt) ?? false
        if (processable) {
            Hackle.app()?.invoke(string: prompt, completionHandler: completionHandler)
        } else {
            uiDelegate?.webView?(
                webView,
                runJavaScriptTextInputPanelWithPrompt: prompt,
                defaultText: defaultText,
                initiatedByFrame: frame,
                completionHandler: completionHandler
            )
        }
    }
}
