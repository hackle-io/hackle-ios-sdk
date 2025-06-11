//
//  DefaultInAppMessageEventTrackerSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultInAppMessageEventTrackerSpecs: QuickSpec {
    override func spec() {
        var core: HackleCoreStub!
        var sut: DefaultInAppMessageEventTracker!

        beforeEach {
            core = HackleCoreStub()
            sut = DefaultInAppMessageEventTracker(core: core)
        }

        it("impression") {
            // given
            let message = InAppMessage.message(
                images: [InAppMessage.image(imagePath: "image_path")],
                text: InAppMessage.text(title: "text_title", body: "text_body"),
                buttons: [
                    InAppMessage.button(text: "button_1"),
                    InAppMessage.button(text: "button_2")
                ]
            )
            let inAppMessage = InAppMessage.create(
                id: 42,
                key: 320,
                messageContext: InAppMessage.messageContext(messages: [message])
            )
            let context = InAppMessage.context(
                inAppMessage: inAppMessage,
                message: message,
                properties: ["decision_reason": DecisionReason.IN_APP_MESSAGE_TARGET]
            )

            // when
            sut.track(context: context, event: .impression, timestamp: Date())

            // then
            expect(core.tracked.count) == 1

            let (event, _, _) = core.tracked[0]
            expect(event.key) == "$in_app_impression"
            expect(event.properties!["in_app_message_id"] as? Int64) == 42
            expect(event.properties!["in_app_message_key"] as? Int64) == 320
            expect(event.properties!["title_text"] as? String) == "text_title"
            expect(event.properties!["body_text"] as? String) == "text_body"
            expect(event.properties!["image_url"] as? [String]) == ["image_path"]
            expect(event.properties!["button_text"] as? [String]) == ["button_1", "button_2"]
            expect(event.properties!["decision_reason"] as? String) == "IN_APP_MESSAGE_TARGET"
            expect(event.internalProperties?["$trigger_event_insert_id"] as? String) == context.triggerEventId
        }

        it("close") {
            // given
            let message = InAppMessage.message(
                images: [InAppMessage.image(imagePath: "image_path")],
                text: InAppMessage.text(title: "text_title", body: "text_body"),
                buttons: [
                    InAppMessage.button(text: "button_1"),
                    InAppMessage.button(text: "button_2")
                ]
            )
            let inAppMessage = InAppMessage.create(
                id: 42,
                key: 320,
                messageContext: InAppMessage.messageContext(messages: [message])
            )
            let context = InAppMessage.context(
                inAppMessage: inAppMessage,
                message: message,
                properties: ["decision_reason": DecisionReason.IN_APP_MESSAGE_TARGET]
            )

            // when
            sut.track(context: context, event: .close, timestamp: Date())

            // then
            expect(core.tracked.count) == 1

            let (event, _, _) = core.tracked[0]
            expect(event.key) == "$in_app_close"
            expect(event.properties!["in_app_message_id"] as? Int64) == 42
            expect(event.properties!["in_app_message_key"] as? Int64) == 320
            expect(event.internalProperties?["$trigger_event_insert_id"] as? String) == context.triggerEventId
        }

        it("button action") {
            // given
            let action = InAppMessage.action(type: .webLink, value: "button_link_click")
            let message = InAppMessage.message(
                images: [InAppMessage.image(imagePath: "image_path")],
                text: InAppMessage.text(title: "text_title", body: "text_body"),
                buttons: [
                    InAppMessage.button(text: "button_1", action: action),
                    InAppMessage.button(text: "button_2")
                ]
            )
            let inAppMessage = InAppMessage.create(
                id: 42,
                key: 320,
                messageContext: InAppMessage.messageContext(messages: [message])
            )
            let context = InAppMessage.context(
                inAppMessage: inAppMessage,
                message: message,
                properties: ["decision_reason": DecisionReason.IN_APP_MESSAGE_TARGET]
            )

            // when
            sut.track(context: context, event: .buttonAction(action: action, button: message.buttons[0]), timestamp: Date())

            // then
            expect(core.tracked.count) == 1

            let (event, _, _) = core.tracked[0]
            expect(event.key) == "$in_app_action"
            expect(event.properties!["in_app_message_id"] as? Int64) == 42
            expect(event.properties!["in_app_message_key"] as? Int64) == 320
            expect(event.properties!["action_area"] as? String) == "BUTTON"
            expect(event.properties!["action_type"] as? String) == "WEB_LINK"
            expect(event.properties!["action_value"] as? String) == "button_link_click"
            expect(event.properties!["button_text"] as? String) == "button_1"
            expect(event.properties!["image_url"]).to(beNil())
            expect(event.properties!["image_order"]).to(beNil())
            expect(event.internalProperties?["$trigger_event_insert_id"] as? String) == context.triggerEventId
        }

        it("image action") {
            // given
            let action = InAppMessage.action(type: .webLink, value: "image_link_click")
            let message = InAppMessage.message(
                images: [InAppMessage.image(imagePath: "image_path")],
                text: InAppMessage.text(title: "text_title", body: "text_body"),
                buttons: [
                    InAppMessage.button(text: "button_1", action: action),
                    InAppMessage.button(text: "button_2")
                ]
            )
            let inAppMessage = InAppMessage.create(
                id: 42,
                key: 320,
                messageContext: InAppMessage.messageContext(messages: [message])
            )
            let context = InAppMessage.context(
                inAppMessage: inAppMessage,
                message: message,
                properties: ["decision_reason": DecisionReason.IN_APP_MESSAGE_TARGET]
            )

            // when
            sut.track(context: context, event: .imageAction(action: action, image: message.images[0], order: 42), timestamp: Date())

            // then
            expect(core.tracked.count) == 1

            let (event, _, _) = core.tracked[0]
            expect(event.key) == "$in_app_action"
            expect(event.properties!["in_app_message_id"] as? Int64) == 42
            expect(event.properties!["in_app_message_key"] as? Int64) == 320
            expect(event.properties!["action_area"] as? String) == "IMAGE"
            expect(event.properties!["action_type"] as? String) == "WEB_LINK"
            expect(event.properties!["action_value"] as? String) == "image_link_click"
            expect(event.properties!["button_text"]).to(beNil())
            expect(event.properties!["image_url"] as? String) == "image_path"
            expect(event.properties!["image_order"] as? Int) == 42
            expect(event.internalProperties?["$trigger_event_insert_id"] as? String) == context.triggerEventId
        }

        it("image impression") {
            // given
            let action = InAppMessage.action(type: .webLink, value: "image_link_click")
            let message = InAppMessage.message(
                images: [InAppMessage.image(imagePath: "image_path")],
                text: InAppMessage.text(title: "text_title", body: "text_body"),
                buttons: [
                    InAppMessage.button(text: "button_1", action: action),
                    InAppMessage.button(text: "button_2")
                ]
            )
            let inAppMessage = InAppMessage.create(
                id: 42,
                key: 320,
                messageContext: InAppMessage.messageContext(messages: [message])
            )
            let context = InAppMessage.context(
                inAppMessage: inAppMessage,
                message: message,
                properties: ["decision_reason": DecisionReason.IN_APP_MESSAGE_TARGET]
            )

            // when
            sut.track(context: context, event: .imageImpression(image: message.images[0], order: 42), timestamp: Date())

            // then
            expect(core.tracked.count) == 1

            let (event, _, _) = core.tracked[0]
            expect(event.key) == "$in_app_image_impression"
            expect(event.properties!["in_app_message_id"] as? Int64) == 42
            expect(event.properties!["in_app_message_key"] as? Int64) == 320
            expect(event.properties!["image_url"] as? String) == "image_path"
            expect(event.properties!["image_order"] as? Int) == 42
            expect(event.internalProperties?["$trigger_event_insert_id"] as? String) == context.triggerEventId
        }
    }
}
