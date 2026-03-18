import Foundation
import UIKit
import WebKit

extension HackleInAppMessageUI {
    class HtmlView: UIView, InAppMessageView {
        let id: String = UUID().uuidString
        let context: InAppMessagePresentationContext
        private let app: HackleApp
        private let contentResolverFactory: InAppMessageHtmlContentResolverFactory
        private let bridgeScript: InAppMessageHtmlBridgeScript

        init(
            context: InAppMessagePresentationContext,
            app: HackleApp,
            contentResolverFactory: InAppMessageHtmlContentResolverFactory,
            bridgeScript: InAppMessageHtmlBridgeScript
        ) {
            self.context = context
            self.app = app
            self.contentResolverFactory = contentResolverFactory
            self.bridgeScript = bridgeScript
            super.init(frame: .zero)

            alpha = 0
            addSubview(webView)
            layoutContent()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Layout

        private var contentConstraints: Constraints?

        private func layoutContent() {
            contentConstraints?.deactivate()
            contentConstraints = Constraints {
                webView.anchors.pin()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layoutFrameIfNeeded()
        }

        private var frameConstraintsInstalled = false

        private func layoutFrameIfNeeded() {
            guard let superview = superview, !frameConstraintsInstalled else {
                return
            }
            frameConstraintsInstalled = true

            anchors.pin()

            setNeedsLayout()
            superview.layoutIfNeeded()
        }

        // MARK: - Presentation

        var presented: Bool = false {
            didSet {
                alpha = presented ? 1 : 0
            }
        }

        func present() {
            willPresent()
            layoutFrameIfNeeded()

            UIView.performWithoutAnimation {
                superview?.layoutIfNeeded()
            }

            resolveAndLoad()
        }

        func dismiss() {
            webView.stopLoading()
            webView.navigationDelegate = nil

            if !presented {
                cleanup()
                return
            }

            willDismiss()

            isUserInteractionEnabled = false
            UIView.animate(
                withDuration: 0.1,
                animations: {
                    self.presented = false
                },
                completion: { _ in
                    self.handle(event: .close(timestamp: self.clock.now()))
                    self.didDismiss()
                }
            )
        }

        // MARK: - Content

        private func resolveAndLoad() {
            do {
                guard let html = context.message.html else {
                    throw HackleError.error("Not found Html [\(inAppMessage.id)]")
                }

                let resolver = try contentResolverFactory.get(resourceType: html.resourceType)
                resolver.resolve(html: html) { [weak self] result in
                    Task { @MainActor in
                        switch result {
                        case .success(let content):
                            self?.webView.load(html: content)
                        case .failure:
                            self?.dismiss()
                        }
                    }
                }
            } catch {
                Log.error("Failed to resolve Html content: \(error) [\(inAppMessage.id)]")
                dismiss()
            }
        }

        private func showContent() {
            window?.makeKey()
            UIView.animate(
                withDuration: 0.1,
                animations: {
                    self.presented = true
                    self.superview?.layoutIfNeeded()
                },
                completion: { _ in
                    self.handle(event: .impression(timestamp: self.clock.now()))
                    self.didPresent()
                }
            )
        }

        // MARK: - Views

        lazy var webView: WebView = {
            let configuration = WKWebViewConfiguration()
            configuration.suppressesIncrementalRendering = true
            configuration.allowsInlineMediaPlayback = true

            let webView = WebView(configuration: configuration)
            webView.navigationDelegate = self

            let javascriptBridge = InAppMessageViewJavascriptBridge(invocator: app.invocator(), sdkKey: app.sdk.key, viewId: id)
            javascriptBridge.apply(to: webView)

            return webView
        }()
    }
}

// MARK: - WKNavigationDelegate

extension HackleInAppMessageUI.HtmlView: WKNavigationDelegate {
    /// Intercept WebView links if necessary.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url, shouldIntercept(navigationAction) {
            decisionHandler(.cancel)
            let action = InAppMessage.Action(behavior: .click, type: .webLink, value: url.absoluteString)
            handle(event: .action(timestamp: clock.now(), action: action, area: nil), type: .action)
        } else {
            decisionHandler(.allow)
        }
    }

    /// Finalizes HTML view after page load:
    /// 1. Disables drag-and-drop and text selection.
    /// 2. Evaluates bridge script to initialize JavaScript SDK.
    /// 3. Presents the HTML content to the user.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.disableDragAndDrop()
        webView.evaluate(script: DisableSelectionScript())
        webView.evaluate(script: bridgeScript) { [weak self] _, _ in
            self?.showContent()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Log.debug("WebView navigation failed: \(error) [\(context.inAppMessage.id)]")
        dismiss()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Log.debug("WebView provisional navigation failed: \(error) [\(context.inAppMessage.id)]")
        dismiss()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        Log.debug("WebView content process did terminate [\(context.inAppMessage.id)]")
        dismiss()
    }
}

extension HackleInAppMessageUI.HtmlView {
    /// Determine whether the WebView link needs to be handled by the App SDK.
    func shouldIntercept(_ navigationAction: WKNavigationAction) -> Bool {
        guard let url = navigationAction.request.url else {
            return false
        }

        // initial HTML load
        if url.host == HackleInAppMessageUI.WebView.baseURL?.host {
            return false
        }

        // user iframe
        if let targetFrame = navigationAction.targetFrame, !targetFrame.isMainFrame {
            return false
        }

        return true
    }

    struct DisableSelectionScript: WebViewUserScript {
        var name: String {
            return "DisableSelectionScript"
        }

        var source: String {
            return """
            (function() {
                const css = '* { -webkit-touch-callout: none; -webkit-user-select: none; } input, textarea { -webkit-touch-callout: initial !important; -webkit-user-select: initial !important; }';
                var style = document.createElement('style');
                style.type = 'text/css';
                style.appendChild(document.createTextNode(css));
                (document.head || document.documentElement).appendChild(style);
            })();
            """
        }
    }
}

private extension WKWebView {
    func disableDragAndDrop() {
        for subview in scrollView.subviews {
            subview.interactions
                .compactMap { $0 as? UIDragInteraction }
                .forEach { subview.removeInteraction($0) }
        }
    }
}
