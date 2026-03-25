import Foundation
import WebKit

/// Sets up `window._hackleApp` on a WKWebView.
/// - injects the bridge script
/// - sets up HackleUIDelegate for invoke handling.
class HackleJavascriptBridge: WebViewUserScript {
    private let invocator: HackleInvocator
    private let sdkKey: String
    private let mode: HackleAppMode
    private let webViewConfig: HackleWebViewConfig

    init(
        invocator: HackleInvocator,
        sdkKey: String,
        mode: HackleAppMode,
        webViewConfig: HackleWebViewConfig
    ) {
        self.invocator = invocator
        self.sdkKey = sdkKey
        self.mode = mode
        self.webViewConfig = webViewConfig
    }

    // MARK: - WebViewUserScript

    var name: String {
        "HackleJavascriptBridge"
    }

    /// ```
    /// window._hackleApp = {
    ///   getAppSdkKey: function() { return '{{SDK_KEY}}' },
    ///   getAppMode: function() { return 'native' },
    ///   getWebViewConfig: function() { return '{...}' },
    ///   getInvocationType: function() { return 'prompt' }
    /// }
    /// ```
    final var source: String {
        let properties = (baseProperties + additionalProperties).map { $0.source }.joined(separator: ",")
        return "window._hackleApp = {\(properties)}"
    }

    // MARK: - Javascript Property

    private var baseProperties: [Property] {
        return [
            Property(name: "getAppSdkKey", value: sdkKey),
            Property(name: "getAppMode", value: mode.description),
            Property(name: "getWebViewConfig", value: webViewConfig.toJsonString()),
            Property(name: "getInvocationType", value: "prompt"),
        ]
    }

    var additionalProperties: [Property] {
        return []
    }

    struct Property {
        let name: String
        let value: String

        var source: String {
            return "\(name): function() { return '\(value)' }"
        }
    }
}

extension HackleJavascriptBridge {
    /// Injects `window._hackleApp` script and sets up HackleUIDelegate for invoke handling.
    @MainActor
    func apply(to webView: WKWebView, uiDelegate: WKUIDelegate? = nil) {
        // 1. Inject bridge script
        webView.addUserScript(script: self)

        // 2. Set up prompt() interception for invoke
        let originalDelegate = uiDelegate ?? webView.uiDelegate
        webView._uiDelegate = HackleUIDelegate(invocator: invocator, uiDelegate: originalDelegate)
        webView.uiDelegate = webView._uiDelegate
    }
}

extension HackleWebViewConfig: Encodable {
    enum CodingKeys: String, CodingKey {
        case automaticRouteTracking
        case automaticScreenTracking
        case automaticEngagementTracking
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(automaticRouteTracking, forKey: .automaticRouteTracking)
        try container.encode(automaticScreenTracking, forKey: .automaticScreenTracking)
        try container.encode(automaticEngagementTracking, forKey: .automaticEngagementTracking)
    }

    func toJsonString() -> String {
        guard let jsonData = try? JSONEncoder().encode(self),
              let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return "{}"
        }
        return jsonString
    }
}

extension WKWebView {
    func prepareForHackleJavascriptBridge(invocator: HackleInvocator, sdkKey: String, mode: HackleAppMode, webViewConfig: HackleWebViewConfig, uiDelegate: WKUIDelegate? = nil) {
        let javascriptBridge = HackleJavascriptBridge(invocator: invocator, sdkKey: sdkKey, mode: mode, webViewConfig: webViewConfig)
        javascriptBridge.apply(to: self, uiDelegate: uiDelegate)
    }
}

private extension WKWebView {
    @MainActor
    struct AssociatedKeys {
        static let _uiDelegate: UnsafeRawPointer = {
            let key = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
            return UnsafeRawPointer(key)
        }()
    }

    var _uiDelegate: HackleUIDelegate? {
        get {
            objc_getAssociatedObject(
                self,
                AssociatedKeys._uiDelegate
            ) as? HackleUIDelegate
        }
        set {
            objc_setAssociatedObject(
                self,
                AssociatedKeys._uiDelegate,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
