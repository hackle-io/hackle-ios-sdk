#if DEBUG
import Foundation
import Network

final class DevToolsStream {

    private let connection: NWConnection
    private let queue: DispatchQueue

    init(connection: NWConnection, queue: DispatchQueue) {
        self.connection = connection
        self.queue = queue
        Self.watch(connection)
    }

    func send(_ data: Data) {
        dispatchPrecondition(condition: .onQueue(queue))
        let connection = connection
        connection.send(content: data, completion: .contentProcessed { error in
            if error != nil {
                connection.cancel()
            }
        })
    }

    func cancel() {
        dispatchPrecondition(condition: .onQueue(queue))
        connection.cancel()
    }

    private static func watch(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { _, _, isComplete, error in
            if isComplete || error != nil {
                connection.cancel()
            } else {
                watch(connection)
            }
        }
    }
}
#endif
