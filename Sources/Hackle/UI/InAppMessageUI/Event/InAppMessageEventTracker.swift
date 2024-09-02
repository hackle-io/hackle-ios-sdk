//
//  InAppMessageEventTracker.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation

protocol InAppMessageEventTracker {
    func track(context: InAppMessagePresentationContext, event: InAppMessage.Event, timestamp: Date)
}

class DefaultInAppMessageEventTracker: InAppMessageEventTracker {
    private let core: HackleCore

    init(core: HackleCore) {
        self.core = core
    }

    func track(context: InAppMessagePresentationContext, event: InAppMessage.Event, timestamp: Date) {
        let trackEvent = createEvent(context: context, event: event)
        core.track(event: trackEvent, user: context.user, timestamp: timestamp)
    }

    private static let IMPRESSION_EVENT_KEY = "$in_app_impression"
    private static let CLOSE_EVENT_KEY = "$in_app_close"
    private static let ACTION_EVENT_KEY = "$in_app_action"

    private func createEvent(context: InAppMessagePresentationContext, event: InAppMessage.Event) -> Event {
        switch event {
        case .impression:
            return Event.builder(DefaultInAppMessageEventTracker.IMPRESSION_EVENT_KEY)
                .properties(context.properties)
                .property("in_app_message_id", context.inAppMessage.id)
                .property("in_app_message_key", context.inAppMessage.key)
                .property("in_app_message_display_type", context.message.layout.displayType)
                .property("in_app_message_layout_type", context.message.layout.layoutType)
                .property("title_text", context.message.text?.title.text)
                .property("body_text", context.message.text?.body.text)
                .property("button_text", context.message.buttons.map {
                    $0.text
                })
                .property("image_url", context.message.images.map {
                    $0.imagePath
                })
                .build()
        case .close:
            return Event.builder(DefaultInAppMessageEventTracker.CLOSE_EVENT_KEY)
                .properties(context.properties)
                .property("in_app_message_id", context.inAppMessage.id)
                .property("in_app_message_key", context.inAppMessage.key)
                .property("in_app_message_display_type", context.message.layout.displayType)
                .property("in_app_message_layout_type", context.message.layout.layoutType)
                .build()
        case .action(let action, let area, let text):
            return Event.builder(DefaultInAppMessageEventTracker.ACTION_EVENT_KEY)
                .properties(context.properties)
                .property("in_app_message_id", context.inAppMessage.id)
                .property("in_app_message_key", context.inAppMessage.key)
                .property("in_app_message_display_type", context.message.layout.displayType)
                .property("in_app_message_layout_type", context.message.layout.layoutType)
                .property("action_area", area.rawValue)
                .property("action_type", action.actionType.rawValue)
                .property("action_value", action.value)
                .property("button_text", text)
                .build()
        }
    }
}
