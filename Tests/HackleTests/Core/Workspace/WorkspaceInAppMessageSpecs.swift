//
//  WorkspaceInAppMessageSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/28.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class WorkspaceInAppMessageSpecs: QuickSpec {
    override func spec() {
        it("valid") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!

            expect(workspace.inAppMessages.count) == 1

            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 1)!
            expect(iam.id) == 1
            expect(iam.key) == 1
            expect(iam.status) == .active
            expect("\(iam.period)") == "range(startInclusive: 1970-01-01 00:00:42 +0000, endExclusive: 1970-01-01 00:00:43 +0000)"

            expect(iam.eventTrigger.frequencyCap!.identifierCaps.count) == 2
            expect(iam.eventTrigger.frequencyCap!.identifierCaps[0].identifierType) == "$sessionId"
            expect(iam.eventTrigger.frequencyCap!.identifierCaps[0].count) == 42
            expect(iam.eventTrigger.frequencyCap!.identifierCaps[1].identifierType) == "$deviceId"
            expect(iam.eventTrigger.frequencyCap!.identifierCaps[1].count) == 43

            expect(iam.eventTrigger.frequencyCap!.durationCap!.duration) == 60 * 60 * 320
            expect(iam.eventTrigger.frequencyCap!.durationCap!.count) == 420

            expect(iam.eventTrigger.rules.count) == 1
            expect(iam.eventTrigger.rules[0].eventKey) == "view_home"
            expect(iam.eventTrigger.rules[0].targets.count) == 1
            expect(iam.eventTrigger.rules[0].targets[0].conditions.count) == 1

            expect(iam.eventTrigger.delay.type) == InAppMessage.DelayType.after
            expect(iam.eventTrigger.delay.afterCondition!.duration) == 42.0

            expect(iam.evaluateContext.atDeliverTime) == true

            expect(iam.targetContext.targets.count) == 1
            expect(iam.targetContext.overrides.count) == 1
            expect(iam.targetContext.overrides[0].identifierType) == "$id"
            expect(iam.targetContext.overrides[0].identifiers) == ["user"]

            expect(iam.messageContext.platformTypes) == [.android, .ios]
            expect(iam.messageContext.orientations) == [.vertical, .horizontal]
            expect(iam.messageContext.messages.count) == 1
            expect(iam.messageContext.messages[0].lang) == "ko"
            expect(iam.messageContext.messages[0].layout.displayType) == .modal
            expect(iam.messageContext.messages[0].layout.layoutType) == .imageOnly
            expect(iam.messageContext.messages[0].layout.alignment?.horizontal) == .left
            expect(iam.messageContext.messages[0].layout.alignment?.vertical) == .top

            expect(iam.messageContext.messages[0].images.count) == 2
            expect(iam.messageContext.messages[0].images[0].orientation) == .vertical
            expect(iam.messageContext.messages[0].images[0].imagePath) == "https://vertical-image.png"
            expect(iam.messageContext.messages[0].images[0].action?.behavior) == .click
            expect(iam.messageContext.messages[0].images[0].action?.actionType) == .webLink
            expect(iam.messageContext.messages[0].images[0].action?.value) == "https://www.hackle.io"
            expect(iam.messageContext.messages[0].images[1].orientation) == .horizontal
            expect(iam.messageContext.messages[0].images[1].imagePath) == "https://horizontal-image.png"
            expect(iam.messageContext.messages[0].images[1].action?.behavior) == .click
            expect(iam.messageContext.messages[0].images[1].action?.actionType) == .webLink
            expect(iam.messageContext.messages[0].images[1].action?.value) == "https://www.hackle.io"

            expect(iam.messageContext.messages[0].imageAutoScroll?.interval) == 42.0

            expect(iam.messageContext.messages[0].text?.title.text) == "title_text"
            expect(iam.messageContext.messages[0].text?.title.style.textColor) == "#0000FF"
            expect(iam.messageContext.messages[0].text?.body.text) == "body_text"
            expect(iam.messageContext.messages[0].text?.body.style.textColor) == "#000000"

            expect(iam.messageContext.messages[0].buttons.count) == 2
            expect(iam.messageContext.messages[0].buttons[0].text) == "close"
            expect(iam.messageContext.messages[0].buttons[0].style.textColor) == "#000000"
            expect(iam.messageContext.messages[0].buttons[0].style.borderColor) == "#FFFFFF"
            expect(iam.messageContext.messages[0].buttons[0].style.borderColor) == "#FFFFFF"
            expect(iam.messageContext.messages[0].buttons[0].action.behavior) == .click
            expect(iam.messageContext.messages[0].buttons[0].action.actionType) == .hidden
            expect(iam.messageContext.messages[0].buttons[0].action.value) == ""
            expect(iam.messageContext.messages[0].buttons[1].text) == "apply"
            expect(iam.messageContext.messages[0].buttons[1].style.textColor) == "#ffffff"
            expect(iam.messageContext.messages[0].buttons[1].style.bgColor) == "#5e5af4"
            expect(iam.messageContext.messages[0].buttons[1].style.borderColor) == "#FFFFFF"
            expect(iam.messageContext.messages[0].buttons[1].action.behavior) == .click
            expect(iam.messageContext.messages[0].buttons[1].action.actionType) == .webLink
            expect(iam.messageContext.messages[0].buttons[1].action.value) == "https://dashboard.hackle.io"

            expect(iam.messageContext.messages[0].background.color) == "#FFFFFF"

            expect(iam.messageContext.messages[0].closeButton?.style.textColor) == "#000001"
            expect(iam.messageContext.messages[0].closeButton?.action.behavior) == .click
            expect(iam.messageContext.messages[0].closeButton?.action.actionType) == .close

            expect(iam.messageContext.messages[0].outerButtons.count) == 1
            expect(iam.messageContext.messages[0].outerButtons[0].button.text) == "outer"
            expect(iam.messageContext.messages[0].outerButtons[0].button.style.textColor) == "#000000"
            expect(iam.messageContext.messages[0].outerButtons[0].button.style.bgColor) == "#FFFFFF"
            expect(iam.messageContext.messages[0].outerButtons[0].button.style.borderColor) == "#FFFFFF"
            expect(iam.messageContext.messages[0].outerButtons[0].button.action.behavior) == .click
            expect(iam.messageContext.messages[0].outerButtons[0].button.action.actionType) == .close
            expect(iam.messageContext.messages[0].outerButtons[0].alignment.horizontal) == .right
            expect(iam.messageContext.messages[0].outerButtons[0].alignment.vertical) == .bottom

            expect(iam.messageContext.messages[0].innerButtons.count) == 1
            expect(iam.messageContext.messages[0].innerButtons[0].button.text) == "inner"
            expect(iam.messageContext.messages[0].innerButtons[0].button.style.textColor) == "#000000"
            expect(iam.messageContext.messages[0].innerButtons[0].button.style.bgColor) == "#FFFFFF"
            expect(iam.messageContext.messages[0].innerButtons[0].button.style.borderColor) == "#FFFFFF"
            expect(iam.messageContext.messages[0].innerButtons[0].button.action.behavior) == .click
            expect(iam.messageContext.messages[0].innerButtons[0].button.action.actionType) == .close
            expect(iam.messageContext.messages[0].innerButtons[0].alignment.horizontal) == .right
            expect(iam.messageContext.messages[0].innerButtons[0].alignment.vertical) == .bottom
        }

        it("invalid") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam_invalid").fetch()!
            expect(workspace.inAppMessages.count) == 0
        }
    }
}
