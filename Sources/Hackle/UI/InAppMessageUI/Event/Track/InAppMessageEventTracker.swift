import Foundation

protocol InAppMessageEventTracker {
    func track(context: InAppMessagePresentationContext, event: InAppMessageViewEvent)
}

class DefaultInAppMessageEventTracker: InAppMessageEventTracker {
    private let core: HackleCore

    init(core: HackleCore) {
        self.core = core
    }

    func track(context: InAppMessagePresentationContext, event: InAppMessageViewEvent) {
        guard let trackEvent = createEvent(context: context, event: event) else {
            return
        }
        core.track(event: trackEvent, user: context.user, timestamp: event.timestamp)
    }

    private static let IMPRESSION_EVENT_KEY = "$in_app_impression"
    private static let IMAGE_IMPRESSION_EVENT_KEY = "$in_app_image_impression"
    private static let CLOSE_EVENT_KEY = "$in_app_close"
    private static let ACTION_EVENT_KEY = "$in_app_action"

    private func createEvent(context: InAppMessagePresentationContext, event: InAppMessageViewEvent) -> Event? {
        switch event.type {
        case .impression:
            return Event.builder(DefaultInAppMessageEventTracker.IMPRESSION_EVENT_KEY)
                .properties(context: context)
                .property("title_text", context.message.text?.title.text)
                .property("body_text", context.message.text?.body.text)
                .property("button_text", context.message.buttons.map {
                    $0.text
                })
                .property("image_url", context.message.images.map {
                    $0.imagePath
                })
                .build()
        case .imageImpression:
            guard let event = event as? InAppMessageViewImageImpressionEvent else { return nil }
            return Event.builder(DefaultInAppMessageEventTracker.IMAGE_IMPRESSION_EVENT_KEY)
                .properties(context: context)
                .property("image_url", event.image.imagePath)
                .property("image_order", event.order)
                .build()
        case .close:
            return Event.builder(DefaultInAppMessageEventTracker.CLOSE_EVENT_KEY)
                .properties(context.properties)
                .property("in_app_message_id", context.inAppMessage.id)
                .property("in_app_message_key", context.inAppMessage.key)
                .property("in_app_message_display_type", context.message.layout.displayType.rawValue)
                .build()
        case .action:
            guard let event = event as? InAppMessageViewActionEvent else { return nil }
            return Event.builder(DefaultInAppMessageEventTracker.ACTION_EVENT_KEY)
                .properties(context: context)
                .property("action_area", event.area?.rawValue)
                .property("action_type", event.action.actionType.rawValue)
                .property("action_value", event.action.value)
                .property("button_text", event.button?.text)
                .property("image_url", event.image?.imagePath)
                .property("image_order", event.imageOrder)
                .property("element_id", event.elementId)
                .build()
        }
    }
}

private extension HackleEventBuilder {
    func properties(context: InAppMessagePresentationContext) -> HackleEventBuilder {
        properties(context.properties)
        property("in_app_message_id", context.inAppMessage.id)
        property("in_app_message_key", context.inAppMessage.key)
        property("in_app_message_display_type", context.message.layout.displayType.rawValue)
        property("decision_reason", context.decisionReason)
        return self
    }
}
