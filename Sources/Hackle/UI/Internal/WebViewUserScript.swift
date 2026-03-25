import Foundation
import WebKit

/// JavaScript that can be injected into or evaluated on a WKWebView.
/// Each script has a unique `name` — only one script per name can exist on a WebView.
///
/// Two execution modes are available via WKWebView extensions:
/// - addUserScript: inject before page load (atDocumentStart) for bridge setup
/// - evaluate:      run on the current page after load (e.g., in didFinish)
protocol WebViewUserScript {
    /// Unique name for this script.
    /// Only one script per name can exist on a WebView.
    var name: String { get }

    /// The JavaScript source code.
    var source: String { get }
}

extension WKWebView {
    /// Injects the script as a WKUserScript. Replaces any existing script with the same name.
    func addUserScript(script: WebViewUserScript, injectionTime: WKUserScriptInjectionTime = .atDocumentStart) {
        let prefix = "/* Hackle:\(script.name) */"
        let source = "\(prefix)\n\(script.source)"
        let userContentController = configuration.userContentController
        let existing = userContentController.userScripts.filter { !$0.source.hasPrefix(prefix) }
        userContentController.removeAllUserScripts()
        userContentController.addUserScript(
            WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: true)
        )
        existing.forEach { userContentController.addUserScript($0) }
    }

    /// Evaluates the script on the current page.
    func evaluate(script: WebViewUserScript, completion: ((Any?, Error?) -> Void)? = nil) {
        evaluateJavaScript(script.source, completionHandler: completion)
    }
}
