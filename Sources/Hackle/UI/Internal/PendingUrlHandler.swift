//
//  PendingUrlHandler.swift
//  Hackle
//

import Foundation

/// Placeholder handler used until the host app installs its own via `setHandler`.
/// Links are held regardless of scheme until initialization.
/// Only the most recent link is kept.
final class PendingUrlHandler: UrlHandler, @unchecked Sendable {
    @MainActor private(set) var pendingUrl: URL?

    @MainActor func open(url: URL) {
        guard url.scheme != nil else {
            return
        }
        pendingUrl = url
    }

    @MainActor func drain() -> URL? {
        defer { pendingUrl = nil }
        return pendingUrl
    }
}
