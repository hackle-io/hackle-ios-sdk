//
//  InAppMessageSpec.swift
//  HackleTests
//
//  Created by sungwoo.yeo on 11/18/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageSpec: QuickSpec {
    override func spec() {

        describe("InAppMessage.Period") {
            context("when period is ALWAYS") {
                let period = InAppMessage.Period.always

                it("should return true for any timestamp") {
                    let timestamps: [Int64] = [
                        0,
                        1762128000000,
                        Int64.max
                    ]

                    for timestamp in timestamps {
                        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
                        expect(period.within(date: date)).to(beTrue())
                    }
                }
            }

            context("when period is RANGE") {
                it("should return true when timestamp is within range") {
                    let start = Date(timeIntervalSince1970: 100.0)
                    let end = Date(timeIntervalSince1970: 200.0)
                    let period = InAppMessage.Period.range(
                        startInclusive: start,
                        endExclusive: end
                    )

                    // At start (inclusive)
                    expect(period.within(date: Date(timeIntervalSince1970: 100.0))).to(beTrue())

                    // Within range
                    expect(period.within(date: Date(timeIntervalSince1970: 150.0))).to(beTrue())

                    // Just before end
                    expect(period.within(date: Date(timeIntervalSince1970: 199.999))).to(beTrue())
                }

                it("should return false when timestamp is outside range") {
                    let start = Date(timeIntervalSince1970: 100.0)
                    let end = Date(timeIntervalSince1970: 200.0)
                    let period = InAppMessage.Period.range(
                        startInclusive: start,
                        endExclusive: end
                    )

                    // Before start
                    expect(period.within(date: Date(timeIntervalSince1970: 99.999))).to(beFalse())

                    // At end (exclusive)
                    expect(period.within(date: Date(timeIntervalSince1970: 200.0))).to(beFalse())

                    // After end
                    expect(period.within(date: Date(timeIntervalSince1970: 201.0))).to(beFalse())
                }
            }
        }

        describe("InAppMessage.Timetable") {
            context("when timetable is ALL") {
                let timetable = InAppMessage.Timetable.all

                it("should return true for any timestamp") {
                    let timestamps = [
                        Date(timeIntervalSince1970: 0),
                        Date(timeIntervalSince1970: TimeInterval(1762128000000) / 1000.0), // Monday
                        Date(timeIntervalSince1970: TimeInterval(1762214400000) / 1000.0), // Tuesday
                        Date(timeIntervalSince1970: TimeInterval(1762646400000) / 1000.0)  // Sunday
                    ]

                    for timestamp in timestamps {
                        expect(timetable.within(date: timestamp)).to(beTrue())
                    }
                }
            }

            context("when timetable is CUSTOM with empty slots") {
                let timetable = InAppMessage.Timetable.custom(slots: [])

                it("should return false for any timestamp") {
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762128000000) / 1000.0)
                    expect(timetable.within(date: timestamp)).to(beFalse())
                }
            }

            context("when timetable is CUSTOM with single slot") {
                let mondaySlot = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 9 * 60 * 60,  // 09:00
                    endSecondsExclusive: 18 * 60 * 60    // 18:00
                )
                let timetable = InAppMessage.Timetable.custom(slots: [mondaySlot])

                it("should return true when timestamp matches slot") {
                    // 2025-11-03T12:00:00.000Z (Monday 12:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762171200000) / 1000.0)
                    expect(timetable.within(date: timestamp)).to(beTrue())
                }

                it("should return false when timestamp does not match slot") {
                    // 2025-11-04T12:00:00.000Z (Tuesday 12:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762257600000) / 1000.0)
                    expect(timetable.within(date: timestamp)).to(beFalse())
                }
            }

            context("when timetable is CUSTOM with multiple slots") {
                let mondayMorning = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 9 * 60 * 60,   // 09:00
                    endSecondsExclusive: 12 * 60 * 60     // 12:00
                )

                let mondayAfternoon = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 14 * 60 * 60,  // 14:00
                    endSecondsExclusive: 18 * 60 * 60     // 18:00
                )

                let fridayEvening = InAppMessage.TimetableSlot(
                    dayOfWeek: .friday,
                    startSecondsInclusive: 19 * 60 * 60,  // 19:00
                    endSecondsExclusive: 22 * 60 * 60     // 22:00
                )

                let timetable = InAppMessage.Timetable.custom(slots: [
                    mondayMorning,
                    mondayAfternoon,
                    fridayEvening
                ])

                it("should return true when matching first slot") {
                    // 2025-11-03T10:00:00.000Z (Monday 10:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762164000000) / 1000.0)
                    expect(timetable.within(date: timestamp)).to(beTrue())
                }

                it("should return true when matching second slot") {
                    // 2025-11-03T15:00:00.000Z (Monday 15:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762182000000) / 1000.0)
                    expect(timetable.within(date: timestamp)).to(beTrue())
                }

                it("should return true when matching third slot") {
                    // 2025-11-07T20:00:00.000Z (Friday 20:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762545600000) / 1000.0)
                    expect(timetable.within(date: timestamp)).to(beTrue())
                }

                it("should return false when matching no slots") {
                    // 2025-11-03T13:00:00.000Z (Monday 13:00 UTC - between morning and afternoon)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762174800000) / 1000.0)
                    expect(timetable.within(date: timestamp)).to(beFalse())
                }
            }
        }

        describe("InAppMessage.ActionType") {
            describe("shouldClose") {
                it("should return true for close types") {
                    let closeTypes: [InAppMessage.ActionType] = [.close, .hidden, .linkAndClose, .linkNewTabAndClose, .linkNewWindowAndClose]
                    for type in closeTypes {
                        expect(type.shouldClose).to(beTrue(), description: "\(type) should close")
                    }
                }

                it("should return false for non-close types") {
                    let nonCloseTypes: [InAppMessage.ActionType] = [.webLink, .linkNewTab, .linkNewWindow]
                    for type in nonCloseTypes {
                        expect(type.shouldClose).to(beFalse(), description: "\(type) should not close")
                    }
                }
            }

            describe("shouldLink") {
                it("should return true for link types") {
                    let linkTypes: [InAppMessage.ActionType] = [.webLink, .linkAndClose, .linkNewTab, .linkNewTabAndClose, .linkNewWindow, .linkNewWindowAndClose]
                    for type in linkTypes {
                        expect(type.shouldLink).to(beTrue(), description: "\(type) should link")
                    }
                }

                it("should return false for non-link types") {
                    let nonLinkTypes: [InAppMessage.ActionType] = [.close, .hidden]
                    for type in nonLinkTypes {
                        expect(type.shouldLink).to(beFalse(), description: "\(type) should not link")
                    }
                }
            }
        }

        describe("InAppMessage.Action") {
            describe("type") {
                it("should return .close for close and hidden") {
                    let closeAction = InAppMessage.Action(behavior: .click, type: .close, value: nil)
                    let hiddenAction = InAppMessage.Action(behavior: .click, type: .hidden, value: nil)

                    expect(closeAction.type) == .close
                    expect(hiddenAction.type) == .close
                }

                it("should return .link for all link types") {
                    let linkTypes: [InAppMessage.ActionType] = [.webLink, .linkAndClose, .linkNewTab, .linkNewTabAndClose, .linkNewWindow, .linkNewWindowAndClose]
                    for actionType in linkTypes {
                        let action = InAppMessage.Action(behavior: .click, type: actionType, value: "https://example.com")
                        expect(action.type).to(equal(.link), description: "\(actionType) should be .link")
                    }
                }
            }

            describe("close") {
                it("should return CloseActionInfo when actionType shouldClose") {
                    let action = InAppMessage.Action(behavior: .click, type: .close, value: nil)
                    expect(action.close).toNot(beNil())
                    expect(action.close?.hideDuration) == 0
                }

                it("should return CloseActionInfo with hideDuration for hidden type") {
                    let action = InAppMessage.Action(behavior: .click, type: .hidden, value: "3600000")
                    expect(action.close).toNot(beNil())
                    expect(action.close?.hideDuration) == 3600 // 3600000ms = 3600s
                }

                it("should return CloseActionInfo for linkAndClose") {
                    let action = InAppMessage.Action(behavior: .click, type: .linkAndClose, value: "https://example.com")
                    expect(action.close).toNot(beNil())
                    expect(action.close?.hideDuration) == 0
                }

                it("should return nil when actionType should not close") {
                    let action = InAppMessage.Action(behavior: .click, type: .webLink, value: "https://example.com")
                    expect(action.close).to(beNil())
                }
            }

            describe("link") {
                it("should return LinkActionInfo when actionType shouldLink") {
                    let action = InAppMessage.Action(behavior: .click, type: .webLink, value: "https://example.com")
                    expect(action.link).toNot(beNil())
                    expect(action.link?.url) == "https://example.com"
                    expect(action.link?.shouldCloseAfterLink) == false
                }

                it("should set shouldCloseAfterLink to true for linkAndClose") {
                    let action = InAppMessage.Action(behavior: .click, type: .linkAndClose, value: "https://example.com")
                    expect(action.link).toNot(beNil())
                    expect(action.link?.url) == "https://example.com"
                    expect(action.link?.shouldCloseAfterLink) == true
                }

                it("should set shouldCloseAfterLink correctly for new tab/window types") {
                    let linkNewTab = InAppMessage.Action(behavior: .click, type: .linkNewTab, value: "https://example.com")
                    expect(linkNewTab.link?.shouldCloseAfterLink) == false

                    let linkNewTabAndClose = InAppMessage.Action(behavior: .click, type: .linkNewTabAndClose, value: "https://example.com")
                    expect(linkNewTabAndClose.link?.shouldCloseAfterLink) == true

                    let linkNewWindow = InAppMessage.Action(behavior: .click, type: .linkNewWindow, value: "https://example.com")
                    expect(linkNewWindow.link?.shouldCloseAfterLink) == false

                    let linkNewWindowAndClose = InAppMessage.Action(behavior: .click, type: .linkNewWindowAndClose, value: "https://example.com")
                    expect(linkNewWindowAndClose.link?.shouldCloseAfterLink) == true
                }

                it("should use empty string when value is nil") {
                    let action = InAppMessage.Action(behavior: .click, type: .webLink, value: nil)
                    expect(action.link?.url) == ""
                }

                it("should return nil when actionType should not link") {
                    let action = InAppMessage.Action(behavior: .click, type: .close, value: nil)
                    expect(action.link).to(beNil())
                }
            }

            describe("hiddenTimeInterval") {
                it("should return 0 for non-hidden types") {
                    for actionType in InAppMessage.ActionType.allCases where actionType != .hidden {
                        let action = InAppMessage.Action(behavior: .click, type: actionType, value: nil)
                        expect(action.hiddenTimeInterval).to(equal(0), description: "\(actionType) should have 0 interval")
                    }
                }

                it("should return default 24h when value is nil") {
                    let action = InAppMessage.Action(behavior: .click, type: .hidden, value: nil)
                    expect(action.hiddenTimeInterval) == 86400 // 24 * 60 * 60
                }

                it("should convert milliseconds to seconds") {
                    let action = InAppMessage.Action(behavior: .click, type: .hidden, value: "7200000") // 2h in ms
                    expect(action.hiddenTimeInterval) == 7200 // 2h in seconds
                }

                it("should return default 24h when value is not a valid number") {
                    let action = InAppMessage.Action(behavior: .click, type: .hidden, value: "invalid")
                    expect(action.hiddenTimeInterval) == 86400
                }
            }
        }

        describe("InAppMessage.TimetableSlot") {
            context("when testing basic slot matching") {
                let slot = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 9 * 60 * 60,  // 09:00
                    endSecondsExclusive: 18 * 60 * 60    // 18:00
                )

                it("should return true when day and time match") {
                    // 2025-11-03T12:00:00.000Z (Monday 12:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762171200000) / 1000.0)
                    expect(slot.within(date: timestamp)).to(beTrue())
                }

                it("should return false when day matches but time is before range") {
                    // 2025-11-03T08:00:00.000Z (Monday 08:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762156800000) / 1000.0)
                    expect(slot.within(date: timestamp)).to(beFalse())
                }

                it("should return false when day matches but time is after range") {
                    // 2025-11-03T19:00:00.000Z (Monday 19:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762196400000) / 1000.0)
                    expect(slot.within(date: timestamp)).to(beFalse())
                }

                it("should return false when time matches but day is different") {
                    // 2025-11-04T12:00:00.000Z (Tuesday 12:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762257600000) / 1000.0)
                    expect(slot.within(date: timestamp)).to(beFalse())
                }
            }

            context("when testing boundary conditions") {
                let slot = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 9 * 60 * 60,  // 09:00
                    endSecondsExclusive: 18 * 60 * 60    // 18:00
                )

                it("should include start time (inclusive)") {
                    // 2025-11-03T09:00:00.000Z (Monday 09:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762160400000) / 1000.0)
                    expect(slot.within(date: timestamp)).to(beTrue())
                }

                it("should exclude end time (exclusive)") {
                    // 2025-11-03T18:00:00.000Z (Monday 18:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762192800000) / 1000.0)
                    expect(slot.within(date: timestamp)).to(beFalse())
                }

                it("should include one millisecond before end time") {
                    // 2025-11-03T17:59:59.999Z
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762192799999) / 1000.0)
                    expect(slot.within(date: timestamp)).to(beTrue())
                }

                it("should exclude one millisecond before start time") {
                    // 2025-11-03T08:59:59.999Z
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762160399999) / 1000.0)
                    expect(slot.within(date: timestamp)).to(beFalse())
                }
            }

            context("when testing all-day slot") {
                let allDaySlot = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 0,              // 00:00:00.000
                    endSecondsExclusive: 24 * 60 * 60      // 24:00:00.000 (next day 00:00)
                )

                it("should match midnight") {
                    // 2025-11-03T00:00:00.000Z (Monday 00:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762128000000) / 1000.0)
                    expect(allDaySlot.within(date: timestamp)).to(beTrue())
                }

                it("should match noon") {
                    // 2025-11-03T12:00:00.000Z (Monday 12:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762171200000) / 1000.0)
                    expect(allDaySlot.within(date: timestamp)).to(beTrue())
                }

                it("should match last millisecond of day") {
                    // 2025-11-03T23:59:59.999Z
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762214399999) / 1000.0)
                    expect(allDaySlot.within(date: timestamp)).to(beTrue())
                }

                it("should not match next day midnight") {
                    // 2025-11-04T00:00:00.000Z (Tuesday 00:00 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762214400000) / 1000.0)
                    expect(allDaySlot.within(date: timestamp)).to(beFalse())
                }
            }

            context("when testing different days of week") {
                let businessHours = 9 * 60 * 60..<18 * 60 * 60

                for day in DayOfWeek.allCases {
                    it("should match \(day.rawValue) correctly") {
                        let slot = InAppMessage.TimetableSlot(
                            dayOfWeek: day,
                            startSecondsInclusive: TimeInterval(businessHours.lowerBound),
                            endSecondsExclusive: TimeInterval(businessHours.upperBound)
                        )

                        // Get a timestamp for this day at noon
                        let dayTimestamps: [DayOfWeek: Int64] = [
                            .monday: 1762171200000,     // 2025-11-03T12:00:00.000Z
                            .tuesday: 1762257600000,    // 2025-11-04T12:00:00.000Z
                            .wednesday: 1762344000000,  // 2025-11-05T12:00:00.000Z
                            .thursday: 1762430400000,   // 2025-11-06T12:00:00.000Z
                            .friday: 1762516800000,     // 2025-11-07T12:00:00.000Z
                            .saturday: 1762603200000,   // 2025-11-08T12:00:00.000Z
                            .sunday: 1762689600000      // 2025-11-09T12:00:00.000Z
                        ]

                        if let timestampMillis = dayTimestamps[day] {
                            let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampMillis) / 1000.0)
                            expect(slot.within(date: timestamp)).to(beTrue())
                        }
                    }
                }
            }
        }
    }
}
