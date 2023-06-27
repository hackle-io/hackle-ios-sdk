//
//  InAppMessageEventTracker.swift
//  Hackle
//
//  Created by yong on 2023/06/20.
//

import Foundation


extension InAppMessage {
    enum Event {
        case impression
        case close
        case action(Action, ActionArea, String? = nil)
    }
}

protocol InAppMessageEventTracker {
    func track(context: InAppMessageContext, event: InAppMessage.Event)
}

class DefaultInAppMessageEventTracker: InAppMessageEventTracker {

    private let core: HackleCore
    private let userManager: UserManager
    private let userResolver: HackleUserResolver

    init(
        core: HackleCore,
        userManager: UserManager,
        userResolver: HackleUserResolver
    ) {
        self.core = core
        self.userManager = userManager
        self.userResolver = userResolver
    }

    func track(context: InAppMessageContext, event: InAppMessage.Event) {
        let trackEvent = createEvent(context: context, event: event)
        let user = userResolver.resolve(user: userManager.currentUser)
        core.track(event: trackEvent, user: user)
    }


    private static let IMPRESSION_EVENT_KEY = "$in_app_impression"
    private static let CLOSE_EVENT_KEY = "$in_app_close"
    private static let ACTION_EVENT_KEY = "$in_app_action"

    private func createEvent(context: InAppMessageContext, event: InAppMessage.Event) -> Event {
        switch event {
        case .impression:
            return Event.builder(DefaultInAppMessageEventTracker.IMPRESSION_EVENT_KEY)
                .property("in_app_message_id", context.inAppMessage.id)
                .property("in_app_message_key", context.inAppMessage.key)
                .property("title_text", context.message.text?.title.text)
                .property("body_text", context.message.text?.body.text)
                .property("button_text", context.message.buttons.map {
                    $0.text
                })
                .property("image_url", context.message.images.map {
                    $0.imagePath
                })
                .properties(context.properties)
                .build()
        case .close:
            return Event.builder(DefaultInAppMessageEventTracker.CLOSE_EVENT_KEY)
                .property("in_app_message_id", context.inAppMessage.id)
                .property("in_app_message_key", context.inAppMessage.key)
                .build()
        case .action(let action, let area, let text):
            return Event.builder(DefaultInAppMessageEventTracker.ACTION_EVENT_KEY)
                .property("in_app_message_id", context.inAppMessage.id)
                .property("in_app_message_key", context.inAppMessage.key)
                .property("action_area", area.rawValue)
                .property("action_type", action.type.rawValue)
                .property("action_value", action.value)
                .property("button_text", text)
                .build()
        }
    }
}
