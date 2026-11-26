import Foundation

package protocol DevToolsEventListener: AnyObject, Sendable {
    func onEvent(eventType: String, body: String)
    func onLog(insertId: String, level: String, timestamp: Int64, message: String)
}

package enum DevToolsOverrideType: String, Sendable {
    case abTest
    case featureFlag
}

package enum DevToolsOverrideResult: Sendable {
    case success
    case notFound
    case remoteMode
    case notReady
}

package enum DevToolsRegistry {

    private static let eventListenerReference = AtomicReference<DevToolsEventListener?>(value: nil)
    private static let visibilityHandlerReference = AtomicReference<(@MainActor @Sendable (Bool) -> Void)?>(value: nil)
    private static let urlProviderReference = AtomicReference<(@Sendable () -> String?)?>(value: nil)
    private static let workspaceStateProviderReference = AtomicReference<DevToolsWorkspaceStateProvider?>(value: nil)
    private static let manualOverrideManagerReference = AtomicReference<DevToolsManualOverrideManager?>(value: nil)

    package static var sdkVersion: String {
        SdkVersion.CURRENT
    }

    package static func setEventListener(_ listener: DevToolsEventListener?) {
        eventListenerReference.set(newValue: listener)
    }

    package static func setVisibilityHandler(_ handler: (@MainActor @Sendable (Bool) -> Void)?) {
        visibilityHandlerReference.set(newValue: handler)
    }

    package static func setUrlProvider(_ provider: (@Sendable () -> String?)?) {
        urlProviderReference.set(newValue: provider)
    }

    package static func workspaceState() -> Data? {
        guard let state = workspaceStateProviderReference.get()?.state() else {
            return nil
        }
        return Json.serialize(state)
    }

    package static func setOverride(type: DevToolsOverrideType, key: Int64, variation: String) -> DevToolsOverrideResult {
        manualOverrideManagerReference.get()?.set(type: type, key: key, variation: variation) ?? .notReady
    }

    package static func resetOverride(type: DevToolsOverrideType, key: Int64) -> DevToolsOverrideResult {
        manualOverrideManagerReference.get()?.reset(type: type, key: key) ?? .notReady
    }

    package static func resetAllOverrides(type: DevToolsOverrideType) -> DevToolsOverrideResult {
        manualOverrideManagerReference.get()?.resetAll(type: type) ?? .notReady
    }

    static func eventListener() -> DevToolsEventListener? {
        eventListenerReference.get()
    }

    static func visibilityHandler() -> (@MainActor @Sendable (Bool) -> Void)? {
        visibilityHandlerReference.get()
    }

    static func url() -> String? {
        urlProviderReference.get()?()
    }

    static func workspaceStateProvider() -> DevToolsWorkspaceStateProvider? {
        workspaceStateProviderReference.get()
    }

    static func setWorkspaceStateProvider(_ provider: DevToolsWorkspaceStateProvider?) {
        workspaceStateProviderReference.set(newValue: provider)
    }

    static func setManualOverrideManager(_ manager: DevToolsManualOverrideManager?) {
        manualOverrideManagerReference.set(newValue: manager)
    }
}
