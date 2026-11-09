import Foundation

final class HackleUrlDispatcher: @unchecked Sendable {

    private let lock = ReadWriteLock(label: "io.hackle.HackleUrlDispatcher")
    private let defaultHandler: UrlHandler
    private var urlHandler: UrlHandler

    init(defaultHandler: UrlHandler) {
        self.defaultHandler = defaultHandler
        self.urlHandler = defaultHandler
    }

    func setDelegate(_ delegate: HackleDelegate?) {
        let handler = delegate.map(DelegateUrlHandler.init) ?? defaultHandler
        let old = lock.write { () -> UrlHandler in
            let old = urlHandler
            urlHandler = handler
            return old
        }
        withExtendedLifetime(old) {}
    }

    @MainActor
    func open(url: URL, channel: HackleURLChannel) {
        let handler = lock.read { urlHandler }
        Log.debug("Dispatch url via \(type(of: handler)) [channel=\(channel)]")
        handler.open(url: url, channel: channel)
    }
}
