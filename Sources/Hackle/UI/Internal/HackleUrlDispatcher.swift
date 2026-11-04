import Foundation

final class HackleUrlDispatcher: @unchecked Sendable {

    private let lock = ReadWriteLock(label: "io.hackle.HackleUrlDispatcher")
    private var urlHandler: UrlHandler

    init(urlHandler: UrlHandler) {
        self.urlHandler = urlHandler
    }

    func setUrlHandler(_ handler: UrlHandler) {
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
        Log.debug("Dispatch url: \(url) via \(type(of: handler))")
        handler.open(url: url, channel: channel)
    }
}
