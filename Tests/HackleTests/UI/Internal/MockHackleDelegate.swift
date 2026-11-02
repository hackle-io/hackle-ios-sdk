import Foundation
@testable import Hackle

final class MockHackleDelegate: NSObject, HackleDelegate, @unchecked Sendable {

    private let lock = NSLock()
    private var _contexts: [HackleURLContext] = []

    var contexts: [HackleURLContext] {
        lock.lock()
        defer { lock.unlock() }
        return _contexts
    }

    @MainActor func handleURL(_ context: HackleURLContext) {
        lock.lock()
        _contexts.append(context)
        lock.unlock()
    }
}
