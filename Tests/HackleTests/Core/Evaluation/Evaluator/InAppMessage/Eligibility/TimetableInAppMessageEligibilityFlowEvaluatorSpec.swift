//
//  TimetableInAppMessageEligibilityFlowEvaluatorSpec.swift
//  HackleTests
//
//  Created by Claude Code on 11/18/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class TimetableInAppMessageEligibilityFlowEvaluatorSpec: QuickSpec {
    override func spec() {

        var sut: TimetableInAppMessageEligibilityFlowEvaluator!
        var evaluatorContext: EvaluatorContext!
        var nextFlow: InAppMessageEligibilityFlow!
        var evaluation: InAppMessageEligibilityEvaluation!

        beforeEach {
            sut = TimetableInAppMessageEligibilityFlowEvaluator()
            evaluatorContext = Evaluators.context()
            evaluation = InAppMessage.eligibilityEvaluation()
            nextFlow = InAppMessageEligibilityFlow.create(evaluation)
        }

        describe("TimetableInAppMessageEligibilityFlowEvaluator") {
            context("when timetable is ALL") {
                it("should proceed to next flow") {
                    let inAppMessage = InAppMessage.create(timetable: .all)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762128000000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual).to(beIdenticalTo(evaluation))
                }
            }

            context("when timetable is CUSTOM with single slot") {
                let mondayBusinessHours = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 9 * 60 * 60,  // 09:00
                    endSecondsExclusive: 18 * 60 * 60    // 18:00
                )

                it("should proceed when timestamp is within slot") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [mondayBusinessHours])
                    )

                    // 2025-11-03T12:00:00.000Z (Monday 12:00 UTC)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762171200000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual).to(beIdenticalTo(evaluation))
                }

                it("should return NOT_IN_IN_APP_MESSAGE_TIMETABLE when timestamp is before slot") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [mondayBusinessHours])
                    )

                    // 2025-11-03T08:00:00.000Z (Monday 08:00 UTC - before 09:00)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762156800000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual?.isEligible).to(beFalse())
                    expect(actual?.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TIMETABLE))
                }

                it("should return NOT_IN_IN_APP_MESSAGE_TIMETABLE when timestamp is after slot") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [mondayBusinessHours])
                    )

                    // 2025-11-03T19:00:00.000Z (Monday 19:00 UTC - after 18:00)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762196400000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual?.isEligible).to(beFalse())
                    expect(actual?.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TIMETABLE))
                }

                it("should return NOT_IN_IN_APP_MESSAGE_TIMETABLE when day is different") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [mondayBusinessHours])
                    )

                    // 2025-11-04T12:00:00.000Z (Tuesday 12:00 UTC)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762257600000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual?.isEligible).to(beFalse())
                    expect(actual?.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TIMETABLE))
                }
            }

            context("when timetable has multiple slots") {
                let mondayMorning = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 9 * 60 * 60,   // 09:00
                    endSecondsExclusive: 12 * 60 * 60     // 12:00
                )

                let tuesdayAfternoon = InAppMessage.TimetableSlot(
                    dayOfWeek: .tuesday,
                    startSecondsInclusive: 14 * 60 * 60,  // 14:00
                    endSecondsExclusive: 17 * 60 * 60     // 17:00
                )

                it("should proceed when matching first slot") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [mondayMorning, tuesdayAfternoon])
                    )

                    // 2025-11-03T10:00:00.000Z (Monday 10:00 UTC)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762164000000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual).to(beIdenticalTo(evaluation))
                }

                it("should proceed when matching second slot") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [mondayMorning, tuesdayAfternoon])
                    )

                    // 2025-11-04T15:00:00.000Z (Tuesday 15:00 UTC)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762268400000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual).to(beIdenticalTo(evaluation))
                }

                it("should return NOT_IN_IN_APP_MESSAGE_TIMETABLE when matching no slots") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [mondayMorning, tuesdayAfternoon])
                    )

                    // 2025-11-05T15:00:00.000Z (Wednesday 15:00 UTC)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762354800000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual?.isEligible).to(beFalse())
                    expect(actual?.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TIMETABLE))
                }
            }

            context("when testing boundary conditions") {
                let slot = InAppMessage.TimetableSlot(
                    dayOfWeek: .monday,
                    startSecondsInclusive: 9 * 60 * 60,  // 09:00
                    endSecondsExclusive: 18 * 60 * 60    // 18:00
                )

                it("should include start time (inclusive)") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [slot])
                    )

                    // 2025-11-03T09:00:00.000Z (Monday 09:00 UTC - exactly start time)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762160400000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual).to(beIdenticalTo(evaluation))
                }

                it("should exclude end time (exclusive)") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [slot])
                    )

                    // 2025-11-03T18:00:00.000Z (Monday 18:00 UTC - exactly end time)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: Date(timeIntervalSince1970: TimeInterval(1762192800000) / 1000.0)
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual?.isEligible).to(beFalse())
                    expect(actual?.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TIMETABLE))
                }

                it("should include one millisecond before end time") {
                    let inAppMessage = InAppMessage.create(
                        timetable: .custom(slots: [slot])
                    )

                    // 2025-11-03T17:59:59.999Z (Monday 17:59:59.999 UTC)
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762192799999) / 1000.0)
                    let request = InAppMessage.eligibilityRequest(
                        inAppMessage: inAppMessage,
                        timestamp: timestamp
                    )

                    let actual = try! sut.evaluate(
                        request: request,
                        context: evaluatorContext,
                        nextFlow: nextFlow
                    )

                    expect(actual).toNot(beNil())
                    expect(actual).to(beIdenticalTo(evaluation))
                }
            }
        }
    }
}
