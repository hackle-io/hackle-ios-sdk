import Foundation

final class DevToolsUserEventListener: UserEventListener {

    private let optOutManager: OptOutManager

    init(optOutManager: OptOutManager) {
        self.optOutManager = optOutManager
    }

    func onEvent(event: UserEvent) {
        guard let listener = DevToolsRegistry.eventListener() else {
            return
        }
        if optOutManager.isOptOutTracking {
            return
        }
        guard let body = Self.body(event) else {
            return
        }
        listener.onEvent(eventType: Self.eventType(event.type), body: body)
    }

    private static let internalKeys = ["internalProperties", "experimentId", "variationId", "eventTypeId", "parameterId", "valueId"]

    private static func body(_ event: UserEvent) -> String? {
        var dto: [String: Any]
        switch event {
        case let exposure as UserEvents.Exposure:
            dto = exposure.toDto()
        case let track as UserEvents.Track:
            dto = track.toDto()
        case let remoteConfig as UserEvents.RemoteConfig:
            dto = remoteConfig.toDto()
        default:
            return nil
        }
        for key in internalKeys {
            dto.removeValue(forKey: key)
        }
        return dto.toJson()
    }

    private static func eventType(_ type: UserEventType) -> String {
        switch type {
        case .exposure: return "exposure"
        case .track: return "track"
        case .remoteConfig: return "remoteConfig"
        }
    }
}
