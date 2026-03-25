import Foundation

class InAppMessageViewJavascriptBridge: HackleJavascriptBridge {
    private let viewId: String

    init(invocator: HackleInvocator, sdkKey: String, viewId: String) {
        self.viewId = viewId
        super.init(invocator: invocator, sdkKey: sdkKey, mode: .native, webViewConfig: Self.webViewConfig)
    }

    override var additionalProperties: [HackleJavascriptBridge.Property] {
        return [Property(name: "getInAppMessageViewId", value: viewId)]
    }

    private static let webViewConfig = HackleWebViewConfig.builder()
        .automaticRouteTracking(false)
        .automaticScreenTracking(false)
        .automaticEngagementTracking(false)
        .build()
}
