import Foundation

final class HackleUrlHandler: @unchecked Sendable {

    static let shared = HackleUrlHandler()

    private let lock = ReadWriteLock(label: "io.hackle.HackleUrlHandler")
    private var _delegate: HackleDelegate?
    private let pending: PendingUrlHandler
    @MainActor private var handler: UrlHandler

    init(handler: UrlHandler? = nil, pending: PendingUrlHandler = PendingUrlHandler()) {
        self.pending = pending
        self.handler = handler ?? pending
    }

    var delegate: HackleDelegate? {
        lock.read { _delegate }
    }

    func setDelegate(_ delegate: HackleDelegate?) {
        let old = lock.write { () -> HackleDelegate? in
            let old = _delegate
            _delegate = delegate
            return old
        }
        withExtendedLifetime(old) {}
    }

    @MainActor
    func setHandler(_ handler: UrlHandler) {
        self.handler = handler
    }

    @MainActor
    func openPendingUrl() {
        guard let url = pending.drain() else {
            return
        }
        open(url: url, channel: .push)
    }

    @MainActor
    func open(url: URL, channel: HackleURLChannel) {
        if let delegate = delegate {
            Log.debug("Delegate handles url: \(url)")
            delegate.handleURL(HackleURLContext(url: url, channel: channel))
        } else {
            Log.debug("UrlHandler opens url: \(url)")
            handler.open(url: url)
        }
    }
}
