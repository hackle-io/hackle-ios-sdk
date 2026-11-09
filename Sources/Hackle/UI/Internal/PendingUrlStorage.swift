import Foundation

final class PendingUrlStorage: @unchecked Sendable {
    @MainActor private(set) var pendingUrl: URL?

    @MainActor func store(url: URL) {
        pendingUrl = url
    }

    @MainActor func drain() -> URL? {
        let url = pendingUrl
        pendingUrl = nil
        return url
    }
}
