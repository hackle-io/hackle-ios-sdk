import Foundation
import WebKit

class WebViewSchemeHandler: NSObject, WKURLSchemeHandler {
    let scheme: String
    private let loader: WebResourceLoader

    init(scheme: String, loader: WebResourceLoader) {
        self.scheme = scheme
        self.loader = loader
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(HackleError.error("WKURLSchemeTask request URL is null"))
            return
        }

        guard let resource = loader.load(url: url) else {
            urlSchemeTask.didFailWithError(HackleError.error("Failed to load WebResource: \(url)"))
            return
        }

        urlSchemeTask.receive(url: url, resource: resource)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

private extension WKURLSchemeTask {
    func receive(url: URL, resource: WebResource) {
        let response = URLResponse(
            url: url,
            mimeType: resource.mimeType,
            expectedContentLength: resource.data.count,
            textEncodingName: resource.encoding
        )
        didReceive(response)
        didReceive(resource.data)
        didFinish()
    }
}

extension WKWebViewConfiguration {
    func setURLSchemeHandler(handler: WebViewSchemeHandler) {
        setURLSchemeHandler(handler, forURLScheme: handler.scheme)
    }
}
