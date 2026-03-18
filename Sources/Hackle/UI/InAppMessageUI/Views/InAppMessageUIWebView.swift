import UIKit
import WebKit

extension HackleInAppMessageUI {
    class WebView: WKWebView {
        init(configuration: WKWebViewConfiguration) {
            super.init(frame: .zero, configuration: configuration)

            backgroundColor = .clear
            isOpaque = false
            scrollView.bounces = false
            scrollView.contentInsetAdjustmentBehavior = .never
            allowsLinkPreview = false
            if #available(iOS 16.4, *) {
                isInspectable = true
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        static let baseURL = URL(string: "https://cache.hackle")

        func load(html: String) {
            loadHTMLString(html, baseURL: Self.baseURL)
        }
    }
}
