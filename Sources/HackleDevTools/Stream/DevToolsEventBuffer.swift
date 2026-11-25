#if DEBUG
import Foundation

final class DevToolsEventBuffer {
    private let capacity: Int
    private var messages: [String] = []

    init(capacity: Int = 500) {
        self.capacity = capacity
    }

    func append(_ message: String) {
        messages.append(message)
        if messages.count > capacity {
            messages.removeFirst(messages.count - capacity)
        }
    }

    func snapshot() -> [String] {
        messages
    }

    func clear() {
        messages.removeAll()
    }
}
#endif
