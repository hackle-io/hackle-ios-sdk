#if DEBUG
import Foundation
import Network
import UIKit
import Hackle

enum DevToolsInterfaces {
    case loopbackOnly
    case wifiAndLoopback
}

final class DevToolsServer: DevToolsEventListener, @unchecked Sendable {

    static let ports: ClosedRange<UInt16> = 47100...47109
    static let maxStreams = 8
    static let pingInterval: TimeInterval = 15

    private static let openTimeout: TimeInterval = 2
    private static let reopenDelay: TimeInterval = 1

    private let interfaces: DevToolsInterfaces
    private let workspaceState: @Sendable () -> Data?
    private let queue = DispatchQueue(label: "io.hackle.devtools.Queue")
    private let buffer = DevToolsEventBuffer(capacity: 500)

    private var token = ""
    private var hello = ""
    private var port: NWEndpoint.Port?
    private var listener: NWListener?
    private var streams: [ObjectIdentifier: DevToolsStream] = [:]
    private var pingTimer: DispatchSourceTimer?
    private var foregroundObserver: NSObjectProtocol?

    init(
        interfaces: DevToolsInterfaces,
        workspaceState: @escaping @Sendable () -> Data? = { DevToolsRegistry.workspaceState() }
    ) {
        self.interfaces = interfaces
        self.workspaceState = workspaceState
    }

    func start(token: String, hello: String) -> UInt16? {
        queue.sync {
            self.token = token
            self.hello = hello
        }
        for rawPort in Self.ports {
            guard let port = NWEndpoint.Port(rawValue: rawPort), let listener = open(port: port) else {
                continue
            }
            queue.sync {
                self.port = port
                self.listener = listener
                startPing()
                observeForeground()
            }
            return rawPort
        }
        return nil
    }

    func stop() {
        queue.sync {
            if let foregroundObserver = foregroundObserver {
                NotificationCenter.default.removeObserver(foregroundObserver)
            }
            foregroundObserver = nil
            pingTimer?.cancel()
            pingTimer = nil
            port = nil
            listener?.cancel()
            listener = nil
            for stream in streams.values {
                stream.cancel()
            }
            streams.removeAll()
        }
    }

    func onEvent(eventType: String, body: String) {
        publish(DevToolsMessages.event(eventType: eventType, body: body))
    }

    func onLog(insertId: String, level: String, timestamp: Int64, message: String) {
        publish(DevToolsMessages.log(insertId: insertId, level: level, timestamp: timestamp, message: message))
    }

    private func publish(_ message: String) {
        queue.async {
            self.buffer.append(message)
            let frame = DevToolsMessages.frame(message)
            for stream in self.streams.values {
                stream.send(frame)
            }
        }
    }

    private func makeListener(on port: NWEndpoint.Port) -> NWListener? {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        let listener: NWListener?
        switch interfaces {
        case .loopbackOnly:
            parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: port)
            listener = try? NWListener(using: parameters)
        case .wifiAndLoopback:
            parameters.prohibitedInterfaceTypes = [.cellular, .wiredEthernet, .other]
            listener = try? NWListener(using: parameters, on: port)
        }
        guard let listener = listener else {
            return nil
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.accept(connection)
        }
        return listener
    }

    private func reopenOnFailure(_ listener: NWListener) {
        listener.stateUpdateHandler = { [weak self, weak listener] state in
            guard case .failed = state, let listener = listener else {
                return
            }
            self?.reopen(replacing: listener)
        }
    }

    private func open(port: NWEndpoint.Port) -> NWListener? {
        guard let listener = makeListener(on: port) else {
            return nil
        }
        let opened = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready, .failed:
                opened.signal()
            default:
                break
            }
        }
        listener.start(queue: queue)
        guard opened.wait(timeout: .now() + Self.openTimeout) == .success, case .ready = listener.state else {
            listener.cancel()
            return nil
        }
        reopenOnFailure(listener)
        return listener
    }

    private func reopen(replacing failed: NWListener) {
        guard listener === failed, let port = port else {
            return
        }
        failed.cancel()
        listener = nil
        queue.asyncAfter(deadline: .now() + Self.reopenDelay) { [weak self] in
            self?.relisten(on: port)
        }
    }

    private func relisten(on port: NWEndpoint.Port) {
        guard listener == nil, self.port == port, let listener = makeListener(on: port) else {
            return
        }
        reopenOnFailure(listener)
        self.listener = listener
        listener.start(queue: queue)
    }

    private func reopenIfNotReady() {
        guard let port = port else {
            return
        }
        if let listener = listener {
            if case .ready = listener.state {
                return
            }
            listener.cancel()
            self.listener = nil
        }
        relisten(on: port)
    }

    private func observeForeground() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.queue.async {
                self.reopenIfNotReady()
            }
        }
    }

    private func startPing() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + Self.pingInterval, repeating: Self.pingInterval)
        timer.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }
            for stream in self.streams.values {
                stream.send(DevToolsMessages.ping)
            }
        }
        pingTimer = timer
        timer.resume()
    }

    private func accept(_ connection: NWConnection) {
        guard listener != nil else {
            connection.cancel()
            return
        }
        let id = ObjectIdentifier(connection)
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed:
                connection.cancel()
            case .cancelled:
                self?.streams.removeValue(forKey: id)
            default:
                break
            }
        }
        connection.start(queue: queue)
        receive(connection, accumulated: Data())
    }

    private func receive(_ connection: NWConnection, accumulated: Data) {
        let remaining = DevToolsHttpRequest.maxHeaderBytes - accumulated.count
        connection.receive(minimumIncompleteLength: 1, maximumLength: remaining) { [weak self] content, _, isComplete, error in
            guard let self = self else {
                connection.cancel()
                return
            }
            var data = accumulated
            if let content = content {
                data.append(content)
            }
            switch DevToolsHttpRequest.parse(data) {
            case .complete(let request):
                self.handle(request, connection: connection)
            case .tooLarge:
                Self.respond(connection, status: 431)
            case .malformed:
                Self.respond(connection, status: 400)
            case .incomplete:
                if data.count >= DevToolsHttpRequest.maxHeaderBytes {
                    Self.respond(connection, status: 431)
                } else if isComplete || error != nil {
                    connection.cancel()
                } else {
                    self.receive(connection, accumulated: data)
                }
            }
        }
    }

    private func handle(_ request: DevToolsHttpRequest, connection: NWConnection) {
        switch DevToolsRouter.route(request, token: token) {
        case .shell:
            Self.respond(connection, status: 200, contentType: "text/html; charset=utf-8", body: DevToolsShellPage.html)
        case .workspace:
            let workspaceState = workspaceState
            DispatchQueue.global(qos: .utility).async {
                guard let state = workspaceState() else {
                    Self.respond(connection, status: 503)
                    return
                }
                Self.respond(connection, status: 200, contentType: "application/json", body: state)
            }
        case .events:
            openStream(connection)
        case .setOverride(let type, let key, let variation):
            respondOverride(connection) { DevToolsRegistry.setOverride(type: type, key: key, variation: variation) }
        case .resetOverride(let type, let key):
            respondOverride(connection) { DevToolsRegistry.resetOverride(type: type, key: key) }
        case .resetAllOverrides(let type):
            respondOverride(connection) { DevToolsRegistry.resetAllOverrides(type: type) }
        case .reject(let status):
            Self.respond(connection, status: status)
        }
    }

    private func respondOverride(_ connection: NWConnection, _ override: @escaping @Sendable () -> DevToolsOverrideResult) {
        DispatchQueue.global(qos: .utility).async {
            let status: Int
            switch override() {
            case .success:
                status = 204
            case .notFound:
                status = 404
            case .remoteMode:
                status = 409
            case .notReady:
                status = 503
            }
            Self.respond(connection, status: status)
        }
    }

    private func openStream(_ connection: NWConnection) {
        guard listener != nil else {
            connection.cancel()
            return
        }
        guard streams.count < Self.maxStreams else {
            Self.respond(connection, status: 503)
            return
        }
        switch connection.state {
        case .failed, .cancelled:
            return
        default:
            break
        }
        let stream = DevToolsStream(connection: connection, queue: queue)
        stream.send(DevToolsHttpResponse.eventStreamHead())
        stream.send(DevToolsMessages.frame(hello))
        for message in buffer.snapshot() {
            stream.send(DevToolsMessages.frame(message))
        }
        streams[ObjectIdentifier(connection)] = stream
    }

    private static func respond(_ connection: NWConnection, status: Int, contentType: String? = nil, body: Data = Data()) {
        let response = DevToolsHttpResponse.make(status: status, contentType: contentType, body: body)
        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
#endif
