//
//  TimeUtilSpec.swift
//  HackleTests
//
//  Created by Claude Code on 11/18/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class TimeUtilSpec: QuickSpec {
    override func spec() {

        describe("TimeUtil") {
            describe("dayOfWeek") {
                context("when given specific timestamps") {
                    it("should return MONDAY for 2025-11-03T00:00:00.000Z") {
                        // 2025-11-03T00:00:00.000Z (Monday)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762128000000) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.monday))
                    }

                    it("should return TUESDAY for 2025-11-04T00:00:00.000Z") {
                        // 2025-11-04T00:00:00.000Z (Tuesday)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762214400000) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.tuesday))
                    }

                    it("should return WEDNESDAY for 2025-11-05T00:00:00.000Z") {
                        // 2025-11-05T00:00:00.000Z (Wednesday)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762300800000) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.wednesday))
                    }

                    it("should return THURSDAY for 2025-11-06T00:00:00.000Z") {
                        // 2025-11-06T00:00:00.000Z (Thursday)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762387200000) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.thursday))
                    }

                    it("should return FRIDAY for 2025-11-07T00:00:00.000Z") {
                        // 2025-11-07T00:00:00.000Z (Friday)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762473600000) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.friday))
                    }

                    it("should return SATURDAY for 2025-11-08T00:00:00.000Z") {
                        // 2025-11-08T00:00:00.000Z (Saturday)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762560000000) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.saturday))
                    }

                    it("should return SUNDAY for 2025-11-09T00:00:00.000Z") {
                        // 2025-11-09T00:00:00.000Z (Sunday)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762646400000) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.sunday))
                    }
                }

                context("when testing day boundaries") {
                    it("should return SUNDAY for last millisecond of Sunday") {
                        // 2025-11-09T23:59:59.999Z (Sunday 23:59:59.999)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762732799999) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.sunday))
                    }

                    it("should return MONDAY for first millisecond of Monday") {
                        // 2025-11-10T00:00:00.000Z (Monday 00:00:00.000)
                        let timestamp = Date(timeIntervalSince1970: TimeInterval(1762732800000) / 1000.0)
                        let result = TimeUtil.dayOfWeek(timestamp)
                        expect(result).toNot(beNil())
                        expect(result).to(equal(.monday))
                    }

                    it("should correctly handle day transition") {
                        // 2025-11-03T23:59:59.999Z (Monday)
                        let lastMsMonday = Date(timeIntervalSince1970: TimeInterval(1762214399999) / 1000.0)
                        let resultMonday = TimeUtil.dayOfWeek(lastMsMonday)
                        expect(resultMonday).toNot(beNil())
                        expect(resultMonday).to(equal(.monday))

                        // 2025-11-04T00:00:00.000Z (Tuesday)
                        let firstMsTuesday = Date(timeIntervalSince1970: TimeInterval(1762214400000) / 1000.0)
                        let resultTuesday = TimeUtil.dayOfWeek(firstMsTuesday)
                        expect(resultTuesday).toNot(beNil())
                        expect(resultTuesday).to(equal(.tuesday))
                    }
                }
            }

            describe("midnight") {
                it("should return midnight for date at midnight") {
                    // 2025-11-03T00:00:00.000Z
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(1762128000000) / 1000.0)
                    let midnight = TimeUtil.midnight(timestamp)

                    expect(midnight.timeIntervalSince1970).to(equal(timestamp.timeIntervalSince1970))
                }

                it("should return midnight for date at noon") {
                    // 2025-11-03T12:00:00.000Z
                    let noon = Date(timeIntervalSince1970: TimeInterval(1762171200000) / 1000.0)
                    let midnight = TimeUtil.midnight(noon)

                    // Expected: 2025-11-03T00:00:00.000Z
                    let expectedMidnight = Date(timeIntervalSince1970: TimeInterval(1762128000000) / 1000.0)
                    expect(midnight.timeIntervalSince1970).to(equal(expectedMidnight.timeIntervalSince1970))
                }

                it("should return midnight for date at last millisecond of day") {
                    // 2025-11-03T23:59:59.999Z
                    let lastMs = Date(timeIntervalSince1970: TimeInterval(1762214399999) / 1000.0)
                    let midnight = TimeUtil.midnight(lastMs)

                    // Expected: 2025-11-03T00:00:00.000Z
                    let expectedMidnight = Date(timeIntervalSince1970: TimeInterval(1762128000000) / 1000.0)
                    expect(midnight.timeIntervalSince1970).to(beCloseTo(expectedMidnight.timeIntervalSince1970, within: 1.0))
                }

                it("should normalize different times to same day midnight") {
                    let morning = Date(timeIntervalSince1970: TimeInterval(1730610000000) / 1000.0) // 05:00
                    let afternoon = Date(timeIntervalSince1970: TimeInterval(1730649600000) / 1000.0) // 16:00
                    let evening = Date(timeIntervalSince1970: TimeInterval(1730671200000) / 1000.0) // 22:00

                    let midnightMorning = TimeUtil.midnight(morning)
                    let midnightAfternoon = TimeUtil.midnight(afternoon)
                    let midnightEvening = TimeUtil.midnight(evening)

                    expect(midnightMorning.timeIntervalSince1970).to(beCloseTo(midnightAfternoon.timeIntervalSince1970, within: 1.0))
                    expect(midnightAfternoon.timeIntervalSince1970).to(beCloseTo(midnightEvening.timeIntervalSince1970, within: 1.0))
                }
            }
        }
    }
}
