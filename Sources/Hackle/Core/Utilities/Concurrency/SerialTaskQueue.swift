import Foundation

/// 제출 순서(FIFO)대로 비동기 작업을 직렬 실행하는 큐. enqueue는 non-blocking이다.
/// - thread safety: `tail` 교체는 lock으로 보호한다 (coreQueue·delay 타이머 등 다중 스레드에서 enqueue됨).
final class SerialTaskQueue: @unchecked Sendable {

    private let lock = RecursiveLock(label: "io.hackle.SerialTaskQueue")
    private var tail: Task<Void, Never>?

    func enqueue(_ operation: @escaping @Sendable () async -> Void) {
        lock.lock {
            let previous = tail
            tail = Task {
                await previous?.value
                await operation()
            }
        }
    }
}
