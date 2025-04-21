import Foundation

class WebViewWrapperUserEventFilter: UserEventFilter {
    func check(event: UserEvent) -> UserEventFilterResult {
        guard PushEventKey.isPushEvent(event: event) else {
            return .block
        }
        guard let deviceId = event.user.deviceId,
              let hackleDeviceId = event.user.hackleDeviceId,
              deviceId != hackleDeviceId
        else {
            return .block
        }
        return .pass
    }
    
    func filter(event: UserEvent) -> UserEvent {
        return event.with(
            user: event.user.toBuilder().clearProperties().build()
        )
    }
}
