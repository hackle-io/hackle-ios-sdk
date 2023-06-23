//
//  InAppMessageEventTracker.swift
//  Hackle
//
//  Created by yong on 2023/06/20.
//

import Foundation


protocol InAppMessageEventTracker {

    func track(context: InAppMessageContext, event: InAppMessage.Event)
}

extension InAppMessage {
    enum Event {
        case impression
        case close
        case action(Action, ActionArea)
    }

    class EventTracker: InAppMessageEventTracker {

        private let core: HackleCore

        init(core: HackleCore) {
            self.core = core
        }

        func track(context: InAppMessageContext, event: Event) {
            Log.debug("InAppMessage.EventTracker.track(\(context.inAppMessage.key), \(event)")
        }
    }
}


//class InAppMessageEventTracker {
//    private let core: HackleCore
//
//    init(core: HackleCore) {
//        self.core = core
//    }
//
//    func onInteraction(context: InAppMessageContext, interaction: InAppMessage.Interaction) {
//    }
//}
//
//extension InAppMessageEventTracker {
//
//    private static let IMPRESSION_EVENT_KEY = "$in_app_impression"
//    private static let CLOSE_EVENT_KEY = "$in_app_close"
//    private static let HIDDEN_EVENT_KEY = "$in_app_hidden"
//    private static let ACTION_EVENT_KEY = "$in_app_action"
//
//    func createEvent(context: InAppMessageContext, interaction: InAppMessage.Interaction) -> Event {
//
//
//        switch interaction {
//        case .impression:
//            return Event.builder(InAppMessageEventTracker.IMPRESSION_EVENT_KEY)
//                .property("in_app_message_id", context.inAppMessage.id)
//                .property("in_app_message_key", context.inAppMessage.key)
//                .property("title_text", context.message.text?.title.text)
//                .property("body_text", context.message.text?.body.text)
//                .property("button_text", context.message.buttons.map {
//                    $0.text
//                })
//                .property("image_url", context.message.images.map {
//                    $0.imagePath
//                })
//                .build()
//        case .close:
//            return Event.builder(InAppMessageEventTracker.CLOSE_EVENT_KEY)
//                .property("in_app_message_id", context.inAppMessage.id)
//                .property("in_app_message_key", context.inAppMessage.key)
//                .build()
//        case .action(let action, let area):
//            return Event.builder(InAppMessageEventTracker.CLOSE_EVENT_KEY)
//                .property("in_app_message_id", context.inAppMessage.id)
//                .property("in_app_message_key", context.inAppMessage.key)
//                .property("action_area", area.rawValue)
//                .property("action_type", action.type.rawValue)
//                .build()
//        }
//    }
//}