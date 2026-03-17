import Foundation

/// Represents event that has occurred in the `InAppMessageView`.
///
/// These are not tracking events (e.g., `TrackEvent`),
/// but view-level occurrences that trigger tracking and action handling.
///
/// Each subtype describes a past fact:
/// - impression: the view has been shown
/// - close: the view has been closed (not a command to close)
/// - action: the user has clicked a button, image, or link
/// - imageImpression: an image has been shown
protocol InAppMessageViewEvent {
    var type: InAppMessageViewEventType { get }
    var timestamp: Date { get }
}

enum InAppMessageViewEventType: String, CaseIterable {
    case impression = "IMPRESSION"
    case close = "CLOSE"
    case action = "ACTION"
    case imageImpression = "IMAGE_IMPRESSION"
}

// MARK: - Impression

struct InAppMessageViewImpressionEvent: InAppMessageViewEvent {
    let timestamp: Date
    var type: InAppMessageViewEventType {
        return .impression
    }
}

extension InAppMessageViewEvent where Self == InAppMessageViewImpressionEvent {
    static func impression(timestamp: Date) -> InAppMessageViewImpressionEvent {
        return InAppMessageViewImpressionEvent(timestamp: timestamp)
    }
}

// MARK: - Close

struct InAppMessageViewCloseEvent: InAppMessageViewEvent {
    let timestamp: Date
    var type: InAppMessageViewEventType {
        return .close
    }
}

extension InAppMessageViewEvent where Self == InAppMessageViewCloseEvent {
    static func close(timestamp: Date) -> InAppMessageViewCloseEvent {
        return InAppMessageViewCloseEvent(timestamp: timestamp)
    }
}

// MARK: - Action

struct InAppMessageViewActionEvent: InAppMessageViewEvent {
    let timestamp: Date
    let action: InAppMessage.Action
    let area: InAppMessage.ActionArea?
    let button: InAppMessage.Message.Button?
    let image: InAppMessage.Message.Image?
    let imageOrder: Int?
    let elementId: String?
    var type: InAppMessageViewEventType {
        return .action
    }
}

extension InAppMessageViewEvent where Self == InAppMessageViewActionEvent {
    static func action(
        timestamp: Date,
        action: InAppMessage.Action,
        button: InAppMessage.Message.Button
    ) -> InAppMessageViewActionEvent {
        return InAppMessageViewActionEvent(
            timestamp: timestamp,
            action: action,
            area: .button,
            button: button,
            image: nil,
            imageOrder: nil,
            elementId: nil
        )
    }

    static func action(
        timestamp: Date,
        action: InAppMessage.Action,
        image: InAppMessage.Message.Image,
        order: Int?
    ) -> InAppMessageViewActionEvent {
        return InAppMessageViewActionEvent(
            timestamp: timestamp,
            action: action,
            area: .image,
            button: nil,
            image: image,
            imageOrder: order,
            elementId: nil
        )
    }

    static func action(
        timestamp: Date,
        action: InAppMessage.Action,
        area: InAppMessage.ActionArea?,
        elementId: String? = nil
    ) -> InAppMessageViewActionEvent {
        return InAppMessageViewActionEvent(
            timestamp: timestamp,
            action: action,
            area: area,
            button: nil,
            image: nil,
            imageOrder: nil,
            elementId: elementId
        )
    }
}

// MARK: - ImageImpression

struct InAppMessageViewImageImpressionEvent: InAppMessageViewEvent {
    let timestamp: Date
    let image: InAppMessage.Message.Image
    let order: Int
    var type: InAppMessageViewEventType {
        return .imageImpression
    }
}

extension InAppMessageViewEvent where Self == InAppMessageViewImageImpressionEvent {
    static func imageImpression(
        timestamp: Date,
        image: InAppMessage.Message.Image,
        order: Int
    ) -> InAppMessageViewImageImpressionEvent {
        return InAppMessageViewImageImpressionEvent(
            timestamp: timestamp,
            image: image,
            order: order
        )
    }
}
