import Foundation
@testable import Hackle

class MockUrlHandler: UrlHandler, @unchecked Sendable {

    private let lock = NSLock()
    private var _openCallCount: Int = 0
    private var _lastOpenedUrl: URL?
    private var _openedUrls: [URL] = []
    private var _channels: [HackleURLChannel] = []

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

    var openedUrls: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return _openedUrls
    }

    var channels: [HackleURLChannel] {
        lock.lock()
        defer { lock.unlock() }
        return _channels
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _openCallCount = 0
        _lastOpenedUrl = nil
        _openedUrls = []
        _channels = []
    }

    @MainActor func open(url: URL, channel: HackleURLChannel) {
        lock.lock()
        _openCallCount += 1
        _lastOpenedUrl = url
        _openedUrls.append(url)
        _channels.append(channel)
        lock.unlock()
    }
}
