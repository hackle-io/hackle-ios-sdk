import Foundation

extension HackleInAppMessageUI {
    class HtmlViewBridgeScript: WebViewUserScript {
        private static let javascriptSdkUrlKey = "$javascript_sdk_url"
        private static let javascriptSdkResource = "hackle-javascript-sdk-11.55.0.min.js"
        private static let defaultJavascriptSdkUrl = WebViewResourceLoader.resourceURL(fileName: javascriptSdkResource)

        private let url: String

        init(url: String) {
            self.url = url
        }

        static func create(config: HackleConfig) -> HtmlViewBridgeScript {
            let url = config.get(javascriptSdkUrlKey) ?? defaultJavascriptSdkUrl.absoluteString
            return HtmlViewBridgeScript(url: url)
        }

        var name: String {
            return "HackleInAppMessageUI.HtmlViewBridgeScript"
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
}
