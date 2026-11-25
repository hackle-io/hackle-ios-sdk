import Foundation
#if DEBUG
import Network
import Hackle
#endif

/// Developer tools that stream Hackle SDK events and user state to a browser viewer on the same network.
///
/// Call ``start()`` and enable `HackleConfigBuilder.devToolsEnabled(_:)`. Events are collected from ``start()``,
/// and the server is open while the user explorer is shown.
///
/// Available only in DEBUG builds. In other builds every member is a no-op.
@objc public final class HackleDevTools: NSObject {

    private override init() {}

    /// Starts collecting events and lets the user explorer open and close the DevTools server.
    @MainActor
    @objc public static func start() {
        #if DEBUG
        prepareServer()
        DevToolsRegistry.setUrlProvider { url }
        DevToolsRegistry.setUserExplorerHandler { shown in
            if shown {
                openServer()
            } else {
                closeServer()
            }
        }
        #endif
    }

    /// The address to open in a browser to view DevTools, or nil if the server is not running.
    @objc public static var url: String? {
        #if DEBUG
        state.lock.lock()
        defer { state.lock.unlock() }
        return state.url
        #else
        nil
        #endif
    }

    /// Sends a log message to the DevTools viewer. The message is not printed to the console.
    @objc public static func log(_ message: String) {
        #if DEBUG
        send(level: "log", message: message)
        #endif
    }

    /// Sends a warning message to the DevTools viewer. The message is not printed to the console.
    @objc public static func warn(_ message: String) {
        #if DEBUG
        send(level: "warn", message: message)
        #endif
    }

    /// Sends an error message to the DevTools viewer. The message is not printed to the console.
    @objc public static func error(_ message: String) {
        #if DEBUG
        send(level: "error", message: message)
        #endif
    }
}

#if DEBUG
extension HackleDevTools {

    private final class State: @unchecked Sendable {
        let lock = NSLock()
        var server: DevToolsServer?
        var token: String?
        var port: UInt16?
        var url: String?
        var monitor: NWPathMonitor?
    }

    private static let state = State()

    private static func send(level: String, message: String) {
        let insertId = UUID().uuidString
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        state.lock.lock()
        let server = state.server
        state.lock.unlock()
        server?.onLog(insertId: insertId, level: level, timestamp: timestamp, message: message)
    }

    private static func prepareServer() {
        state.lock.lock()
        defer { state.lock.unlock() }
        guard state.server == nil else {
            return
        }
        #if targetEnvironment(simulator)
        let interfaces = DevToolsInterfaces.loopbackOnly
        #else
        let interfaces = DevToolsInterfaces.wifiAndLoopback
        #endif
        let server = DevToolsServer(interfaces: interfaces)
        DevToolsRegistry.setEventListener(server)
        state.server = server
    }

    @MainActor
    private static func openServer() {
        state.lock.lock()
        defer { state.lock.unlock() }
        guard let server = state.server, state.port == nil else {
            return
        }
        let token = DevToolsTokenStore.newToken()
        let hello = DevToolsMessages.hello(app: DevToolsAppInfo.current(), sdkVersion: DevToolsRegistry.sdkVersion)
        guard let port = server.start(token: token, hello: hello) else {
            NSLog("Hackle DevTools: failed to open a port in 47100-47109")
            return
        }
        state.token = token
        state.port = port
        publishUrl()
        #if !targetEnvironment(simulator)
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor.pathUpdateHandler = { _ in
            refreshUrl()
        }
        monitor.start(queue: DispatchQueue.global(qos: .utility))
        state.monitor = monitor
        #endif
    }

    @MainActor
    private static func closeServer() {
        state.lock.lock()
        defer { state.lock.unlock() }
        guard state.port != nil else {
            return
        }
        state.monitor?.cancel()
        state.monitor = nil
        state.server?.stop()
        state.token = nil
        state.port = nil
        state.url = nil
    }

    private static func refreshUrl() {
        state.lock.lock()
        defer { state.lock.unlock() }
        publishUrl()
    }

    private static func publishUrl() {
        guard state.server != nil, let token = state.token, let port = state.port else {
            return
        }
        #if targetEnvironment(simulator)
        let host = "127.0.0.1"
        #else
        let host = DevToolsAddressResolver.wifiIPv4() ?? "127.0.0.1"
        #endif
        let url = "http://\(host):\(port)/?token=\(token)"
        guard url != state.url else {
            return
        }
        state.url = url
        NSLog("Hackle DevTools: %@", url)
    }
}
#endif
