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

        /// Base URL that `WebViewResourceLoader` handles.
        /// URLs must be built on top of this base to be resolved by the loader.
        /// `hackle-resource://cache.hackle/`
        static let baseURL = URL(string: "\(scheme)://\(domain)/")!

        /// Converts a bundle file name to a custom-scheme URL.
        /// e.g., `"sdk.min.js"` → `hackle-resource://cache.hackle/sdk.min.js`
        static func resourceURL(fileName: String) -> URL {
            return baseURL.appendingPathComponent(fileName)
        }

        /// Extracts the bundle file name from a custom-scheme URL. Inverse of `resourceURL(fileName:)`.
        /// e.g., `hackle-resource://cache.hackle/sdk.min.js` → `"sdk.min.js"`
        /// Returns `nil` if the URL doesn't match the expected scheme and domain.
        static func fileName(from url: URL) -> String? {
            guard url.scheme == scheme, url.host == domain else {
                return nil
            }

            let name = url.lastPathComponent
            guard !name.isEmpty, name != "/" else {
                return nil
            }
            return name
        }

        /// Resolves a custom-scheme URL to a bundled resource.
        /// Extracts the file name via `fileName(from:)`, then loads it from the app bundle.
        func load(url: URL) -> WebResource? {
            guard let fileName = Self.fileName(from: url) else {
                return nil
            }
            let fileURL = URL(fileURLWithPath: fileName)
            let name = fileURL.deletingPathExtension().lastPathComponent
            let ext = fileURL.pathExtension

            guard !name.isEmpty, !ext.isEmpty else {
                return nil
            }

            guard
                let fileURL = HackleInternalResources.bundle.url(forResource: name, withExtension: ext),
                let data = try? Data(contentsOf: fileURL)
            else {
                return nil
            }

            return WebResource(
                data: data,
                mimeType: mimeType(for: ext),
                encoding: "utf-8"
            )
        }

        private func mimeType(for ext: String) -> String {
            switch ext.lowercased() {
            case "js": return "application/javascript"
            case "css": return "text/css"
            case "html": return "text/html"
            default: return "text/plain"
            }
        }
    }
}
