import Foundation
import WebKit

class HackleUIDelegate: NSObject, WKUIDelegate {
    
    private let uiDelegate: WKUIDelegate?
    
    init(uiDelegate: WKUIDelegate? = nil) {
        self.uiDelegate = uiDelegate
    }
    
    func webView(
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
