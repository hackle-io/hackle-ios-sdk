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

        func load(html: String) {
            loadHTMLString(html, baseURL: WebViewResourceLoader.baseURL)
        }
    }

    /// Loads bundled resources (JS, CSS) via a custom URL scheme (`hackle-resource://`).
    /// Used by `WebViewSchemeHandler` to serve local files to the WebView.
    class WebViewResourceLoader: WebResourceLoader {
        static let scheme = "hackle-resource"
        static let domain = "cache.hackle"

        /// hackle-resource://cache.hackle/
        static let baseURL = URL(string: "\(scheme)://\(domain)/")!

        /// Returns the full custom-scheme URL for a bundled file (e.g., `hackle-resource://cache.hackle/sdk.js`).
        static func resourceURL(fileName: String) -> URL {
            return baseURL.appendingPathComponent(fileName)
        }

        func load(url: URL) -> WebResource? {
            guard url.scheme == Self.scheme, url.host == Self.domain else {
                return nil
            }

            let pathURL = URL(fileURLWithPath: url.lastPathComponent)
            let name = pathURL.deletingPathExtension().lastPathComponent
            let fileExtension = pathURL.pathExtension

            guard !name.isEmpty, !fileExtension.isEmpty else {
                return nil
            }

            guard
                let fileURL = HackleInternalResources.bundle.url(forResource: name, withExtension: fileExtension),
                let data = try? Data(contentsOf: fileURL)
            else {
                return nil
            }

            return WebResource(
                data: data,
                mimeType: mimeType(for: fileExtension),
                encoding: "utf-8"
            )
        }

        private func mimeType(for ext: String) -> String {
            switch ext.lowercased() {
            case "js": return "application/javascript"
            case "css": return "text/css"
            case "html": return"text/html"
            default: return "text/plain"
            }
        }
    }
}
