import Foundation

final class DelegateUrlHandler: UrlHandler, @unchecked Sendable {
    private let delegate: HackleDelegate

    init(delegate: HackleDelegate) {
        self.delegate = delegate
    }

    @MainActor func open(url: URL, channel: HackleURLChannel) {
        delegate.handleURL(HackleURLContext(url: url, channel: channel))
    }
}
