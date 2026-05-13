import Foundation

class InAppMessageViewJavascriptBridge: HackleJavascriptBridge {
    private let viewId: String
    private let triggerEvent: Event

    init(invocator: HackleInvocator, sdkKey: String, viewId: String, triggerEvent: Event) {
        self.viewId = viewId
        self.triggerEvent = triggerEvent
        super.init(invocator: invocator, sdkKey: sdkKey, mode: .native, webViewConfig: Self.webViewConfig)
    }

    override var additionalProperties: [HackleJavascriptBridge.Property] {
        return [
            Property(name: "getInAppMessageViewId", value: viewId),
            Property(name: "getInAppMessageTriggerEvent", value: triggerEventJsonString),
        ]
    }

    private var triggerEventJsonString: String {
        guard let json = triggerEvent.toDictionary().toJson() else {
            Log.error("Failed to serialize trigger event for HTML IAM bridge")
            return ""
        }
        return json.escapedForJsSingleQuotedLiteral()
    }

    private static let webViewConfig = HackleWebViewConfig.builder()
        .automaticRouteTracking(false)
        .automaticScreenTracking(false)
        .automaticEngagementTracking(false)
        .build()
}

private extension String {
    func escapedForJsSingleQuotedLiteral() -> String {
        self
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }
}
