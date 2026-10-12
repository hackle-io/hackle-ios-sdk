//
//  PendingUrlHandler.swift
//  Hackle
//

import Foundation
import UIKit

/// Placeholder handler used until the host app installs its own via `setUrlHandler`.
/// Non-http schemes are opened immediately; http(s) links are held so the
/// configured handler can decide between universal link and open-url routing.
/// Only the most recent link is kept.
final class PendingUrlHandler: UrlHandler, @unchecked Sendable {
    @MainActor private(set) var pendingUrl: URL?

    @MainActor func open(url: URL) {
        guard let scheme = url.scheme else {
            return
        }
        guard UrlSchemes.isHttp(scheme) else {
            UIUtils.application?.open(url, options: [:]) { success in
                Log.debug("Redirected to: \(url.absoluteString) [success=\(success)]")
            }
            return
        }
        pendingUrl = url
    }

    @MainActor func drain() -> URL? {
        defer { pendingUrl = nil }
        return pendingUrl
    }
}
