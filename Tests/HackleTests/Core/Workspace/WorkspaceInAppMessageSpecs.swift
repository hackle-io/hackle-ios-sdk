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

            expect(workspace.inAppMessages.count) == 10

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

        it("timetable - custom with multiple slots") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 1)!

            switch iam.timetable {
            case .custom(let slots):
                expect(slots.count) == 2
                expect(slots[0].dayOfWeek) == .monday
                expect(slots[0].startSecondsInclusive) == 32400
                expect(slots[0].endSecondsExclusive) == 64800
                expect(slots[1].dayOfWeek) == .friday
                expect(slots[1].startSecondsInclusive) == 68400
                expect(slots[1].endSecondsExclusive) == 79200
            default:
                fail("Expected custom timetable for iam key 1")
            }
        }

        it("timetable - all type") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 2)!

            switch iam.timetable {
            case .all:
                expect(true) == true
            default:
                fail("Expected all timetable for iam key 2")
            }
        }

        it("timetable - missing field defaults to all") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 3)!

            switch iam.timetable {
            case .all:
                expect(true) == true
            default:
                fail("Expected all timetable for iam key 3 (missing timetable)")
            }
        }

        it("timetable - invalid dayOfWeek skipped") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 4)!

            switch iam.timetable {
            case .custom(let slots):
                expect(slots.count) == 1
                expect(slots[0].dayOfWeek) == .tuesday
            default:
                fail("Expected custom timetable for iam key 4")
            }
        }

        it("timetable - all invalid slots fallback to all") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 5)!

            switch iam.timetable {
            case .all:
                expect(true) == true
            default:
                fail("Expected all timetable for iam key 5 (all invalid slots)")
            }
        }

        it("timetable - empty slots fallback to all") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 6)!

            switch iam.timetable {
            case .all:
                expect(true) == true
            default:
                fail("Expected all timetable for iam key 6 (empty slots)")
            }
        }

        it("timetable - null value defaults to all") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 7)!

            switch iam.timetable {
            case .all:
                expect(true) == true
            default:
                fail("Expected all timetable for iam key 7 (null timetable)")
            }
        }

        it("timetable - unknown type defaults to all") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 8)!

            switch iam.timetable {
            case .all:
                expect(true) == true
            default:
                fail("Expected all timetable for iam key 8 (unknown type)")
            }
        }

        it("timetable - boundary time full day") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 9)!

            switch iam.timetable {
            case .custom(let slots):
                expect(slots.count) == 1
                expect(slots[0].dayOfWeek) == .wednesday
                expect(slots[0].startSecondsInclusive) == 0
                expect(slots[0].endSecondsExclusive) == 86400
            default:
                fail("Expected custom timetable for iam key 9")
            }
        }

        it("timetable - all days of week") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam").fetch()!
            let iam = workspace.getInAppMessageOrNil(inAppMessageKey: 10)!

            switch iam.timetable {
            case .custom(let slots):
                expect(slots.count) == 7
                expect(slots[0].dayOfWeek) == .monday
                expect(slots[1].dayOfWeek) == .tuesday
                expect(slots[2].dayOfWeek) == .wednesday
                expect(slots[3].dayOfWeek) == .thursday
                expect(slots[4].dayOfWeek) == .friday
                expect(slots[5].dayOfWeek) == .saturday
                expect(slots[6].dayOfWeek) == .sunday
            default:
                fail("Expected custom timetable for iam key 10")
            }
        }

        it("invalid") {
            let workspace = ResourcesWorkspaceFetcher(fileName: "iam_invalid").fetch()!
            expect(workspace.inAppMessages.count) == 0
        }
    }
}
