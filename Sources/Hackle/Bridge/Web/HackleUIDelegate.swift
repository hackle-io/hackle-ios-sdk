import Foundation
import WebKit

class HackleUIDelegate: NSObject, WKUIDelegate {
    
    private let bridge: HackleBridge
    private let uiDelegate: WKUIDelegate?
    
    init(app: HackleApp, uiDelegate: WKUIDelegate? = nil) {
        self.bridge = HackleBridge(app: app)
        self.uiDelegate = uiDelegate
    }
    
    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        let processable = bridge.isInvocableString(string: prompt)
        if (processable) {
            bridge.invoke(string: prompt, completionHandler: completionHandler)
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
