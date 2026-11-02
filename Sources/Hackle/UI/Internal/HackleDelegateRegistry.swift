import Foundation

final class HackleDelegateRegistry: @unchecked Sendable {

    static let shared = HackleDelegateRegistry()

    private let lock = ReadWriteLock(label: "io.hackle.HackleDelegateRegistry")
    private var _delegate: HackleDelegate?

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
    func open(url: URL, channel: HackleURLChannel, urlHandler: UrlHandler) {
        if let delegate = delegate {
            Log.debug("Delegate handles url: \(url)")
            delegate.handleURL(HackleURLContext(url: url, channel: channel))
        } else {
            Log.debug("UrlHandler opens url: \(url)")
            urlHandler.open(url: url)
        }
    }
}
