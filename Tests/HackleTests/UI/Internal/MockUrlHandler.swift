import Foundation
import MockingKit
@testable import Hackle

class MockUrlHandler: Mock, UrlHandler {

    lazy var openMock = MockFunction(self, open)

    // 테스트에서 toEventually로 검증할 수 있는 상태 변수
    private let lock = NSLock()
    private var _openCallCount: Int = 0
    private var _lastOpenedUrl: URL?

    var openCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _openCallCount
    }

    var lastOpenedUrl: URL? {
        lock.lock()
        defer { lock.unlock() }
        return _lastOpenedUrl
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _openCallCount = 0
        _lastOpenedUrl = nil
    }

    @MainActor func open(url: URL) {
        lock.lock()
        _openCallCount += 1
        _lastOpenedUrl = url
        lock.unlock()
        call(openMock, args: url)
    }
}
