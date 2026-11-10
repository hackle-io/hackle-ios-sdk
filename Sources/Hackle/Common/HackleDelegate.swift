import Foundation

/// The channel through which a link was delivered.
@objc public enum HackleURLChannel: Int, Sendable {
    /// A link from a push notification.
    case push
    /// A link from an in-app message.
    case inAppMessage
}

/// Context of a link that Hackle would otherwise open.
@objc public final class HackleURLContext: NSObject, Sendable {
    /// The link to open.
    @objc public let url: URL
    /// The channel through which the link was delivered.
    @objc public let channel: HackleURLChannel

    init(url: URL, channel: HackleURLChannel) {
        self.url = url
        self.channel = channel
        super.init()
    }
}

/// Delegate protocol for handling links from push notifications and in-app messages.
///
/// Register it with ``HackleConfigBuilder/delegate(_:)`` or ``Hackle/setDelegate(_:)``.
/// The SDK does not open links passed to the delegate.
/// The SDK keeps a strong reference to the registered delegate until nil is passed.
@objc public protocol HackleDelegate: AnyObject {
    /// Called on the main thread when a link should be opened.
    ///
    /// - Parameter context: The ``HackleURLContext`` of the link
    @MainActor
    func handleURL(_ context: HackleURLContext)
}
