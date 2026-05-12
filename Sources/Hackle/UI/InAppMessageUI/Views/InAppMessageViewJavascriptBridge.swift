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
            Property(name: "getInAppMessageTriggerEvent", value: triggerEvent.toTriggerEventJsonString()),
        ]
    }

    private static let webViewConfig = HackleWebViewConfig.builder()
        .automaticRouteTracking(false)
        .automaticScreenTracking(false)
        .automaticEngagementTracking(false)
        .build()
}

private extension Event {
    func toTriggerEventJsonString() -> String {
        var dict: [String: Any] = ["key": key]
        if let value = value, value.isFinite {
            dict["value"] = value
        }
        if let properties = properties, !properties.isEmpty {
            dict["properties"] = properties
        }
        guard let json = dict.toJson() else {
            return ""
        }
        return json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
    }
}
