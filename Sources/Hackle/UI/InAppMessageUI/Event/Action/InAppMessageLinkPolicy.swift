import Foundation

/// Decides whether the link of an in-app message may be opened.
///
/// The link comes from the server, and for an HTML in-app message from the script running in the message.
/// Schemes that run script or expose local content are never a valid landing link, so they are rejected
/// before the link reaches the `HackleUrlDispatcher` and a registered `HackleDelegate`.
enum InAppMessageLinkPolicy {

    private static let blockedSchemes: Set<String> = ["javascript", "file", "data", "blob", "about"]

    static func isAllowed(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else {
            return true
        }
        return !blockedSchemes.contains(scheme)
    }
}
