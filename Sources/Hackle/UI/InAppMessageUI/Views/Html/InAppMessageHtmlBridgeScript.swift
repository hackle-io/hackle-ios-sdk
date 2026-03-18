import Foundation

class InAppMessageHtmlBridgeScript: WebViewUserScript {
    private let url: String
    
    init(url: String) {
        self.url = url
    }
    
    var name: String {
        return "InAppMessageHtmlBridgeScript"
    }
    
    var source: String {
        return """
        (function() {
            var s = document.createElement('script');
            s.src = '\(url)';
            s.onload = function() {
                Hackle.setWebAppInAppMessageHtmlBridge();
            };
            document.head.appendChild(s);
        })();
        """
    }
}

extension InAppMessageHtmlBridgeScript {
    private static let javascriptSdkUrlKey = "$javascript_sdk_url"
    private static let defaultJavaScriptSdkUrl = "https://cdn2.hackle.io/npm/@hackler/javascript-sdk@11.55.0/lib/index.browser.umd.min.js"
    
    static func create(config: HackleConfig) -> InAppMessageHtmlBridgeScript {
        let url = config.get(javascriptSdkUrlKey) ?? defaultJavaScriptSdkUrl
        return InAppMessageHtmlBridgeScript(url: url)
    }
}
