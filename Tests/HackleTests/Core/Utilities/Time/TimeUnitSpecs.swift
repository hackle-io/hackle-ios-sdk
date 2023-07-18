import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class TimeUnitSpecs: QuickSpec {
    override func spec() {

        func expectEquals<T: Equatable>(_ expected: T, _ actual: T) {
            expect(actual).to(equal(expected))
        }

        it("convert") {
            expectEquals(1.0, TimeUnit.nanoseconds.convert(1.0, to: .nanoseconds))
            expectEquals(1.0, TimeUnit.microseconds.convert(1.0, to: .microseconds))
            expectEquals(1.0, TimeUnit.milliseconds.convert(1.0, to: .milliseconds))
            expectEquals(1.0, TimeUnit.seconds.convert(1.0, to: .seconds))
            expectEquals(1.0, TimeUnit.minutes.convert(1.0, to: .minutes))
            expectEquals(1.0, TimeUnit.hours.convert(1.0, to: .hours))
            expectEquals(1.0, TimeUnit.days.convert(1.0, to: .days))
        }

        it("nanos") {
            expectEquals(1.0 * (1), TimeUnit.nanosToUnit(nanos: 1.0, unit: .nanoseconds))
            expectEquals(1.0 / (1 * 1_000), TimeUnit.nanosToUnit(nanos: 1.0, unit: .microseconds))
            expectEquals(1.0 / (1 * 1_000 * 1_000), TimeUnit.nanosToUnit(nanos: 1.0, unit: .milliseconds))
            expectEquals(1.0 / (1 * 1_000 * 1_000 * 1_000), TimeUnit.nanosToUnit(nanos: 1.0, unit: .seconds))
            expectEquals(1.0 / (1 * 1_000 * 1_000 * 1_000 * 60), TimeUnit.nanosToUnit(nanos: 1.0, unit: .minutes))
            expectEquals(1.0 / (1 * 1_000 * 1_000 * 1_000 * 60 * 60), TimeUnit.nanosToUnit(nanos: 1.0, unit: .hours))
            expectEquals(1.0 / (1 * 1_000 * 1_000 * 1_000 * 60 * 60 * 24), TimeUnit.nanosToUnit(nanos: 1.0, unit: .days))
        }

        it("micros") {
            expectEquals(1.0 * (1 * 1_000), TimeUnit.microsToUnit(micros: 1.0, unit: .nanoseconds))
            expectEquals(1.0 / (1), TimeUnit.microsToUnit(micros: 1.0, unit: .microseconds))
            expectEquals(1.0 / (1 * 1_000), TimeUnit.microsToUnit(micros: 1.0, unit: .milliseconds))
            expectEquals(1.0 / (1 * 1_000 * 1_000), TimeUnit.microsToUnit(micros: 1.0, unit: .seconds))
            expectEquals(1.0 / (1 * 1_000 * 1_000 * 60), TimeUnit.microsToUnit(micros: 1.0, unit: .minutes))
            expectEquals(1.0 / (1 * 1_000 * 1_000 * 60 * 60), TimeUnit.microsToUnit(micros: 1.0, unit: .hours))
            expectEquals(1.0 / (1 * 1_000 * 1_000 * 60 * 60 * 24), TimeUnit.microsToUnit(micros: 1.0, unit: .days))
        }

        it("millis") {
            expectEquals(1.0 * (1 * 1_000 * 1_000), TimeUnit.millisToUnit(millis: 1.0, unit: .nanoseconds))
            expectEquals(1.0 * (1 * 1_000), TimeUnit.millisToUnit(millis: 1.0, unit: .microseconds))
            expectEquals(1.0 * (1), TimeUnit.millisToUnit(millis: 1.0, unit: .milliseconds))
            expectEquals(1.0 / (1 * 1_000), TimeUnit.millisToUnit(millis: 1.0, unit: .seconds))
            expectEquals(1.0 / (1 * 1_000 * 60), TimeUnit.millisToUnit(millis: 1.0, unit: .minutes))
            expectEquals(1.0 / (1 * 1_000 * 60 * 60), TimeUnit.millisToUnit(millis: 1.0, unit: .hours))
            expectEquals(1.0 / (1 * 1_000 * 60 * 60 * 24), TimeUnit.millisToUnit(millis: 1.0, unit: .days))
        }

        it("seconds") {
            expectEquals(1.0 * (1 * 1_000 * 1_000 * 1_000), TimeUnit.secondsToUnit(seconds: 1.0, unit: .nanoseconds))
            expectEquals(1.0 * (1 * 1_000 * 1_000), TimeUnit.secondsToUnit(seconds: 1.0, unit: .microseconds))
            expectEquals(1.0 * (1 * 1_000), TimeUnit.secondsToUnit(seconds: 1.0, unit: .milliseconds))
            expectEquals(1.0 * (1), TimeUnit.secondsToUnit(seconds: 1.0, unit: .seconds))
            expectEquals(1.0 / (1 * 60), TimeUnit.secondsToUnit(seconds: 1.0, unit: .minutes))
            expectEquals(1.0 / (1 * 60 * 60), TimeUnit.secondsToUnit(seconds: 1.0, unit: .hours))
            expectEquals(1.0 / (1 * 60 * 60 * 24), TimeUnit.secondsToUnit(seconds: 1.0, unit: .days))
        }

        it("minutes") {
            expectEquals(1.0 * (1 * 1_000 * 1_000 * 1_000 * 60), TimeUnit.minutesToUnit(minutes: 1.0, unit: .nanoseconds))
            expectEquals(1.0 * (1 * 1_000 * 1_000 * 60), TimeUnit.minutesToUnit(minutes: 1.0, unit: .microseconds))
            expectEquals(1.0 * (1 * 1_000 * 60), TimeUnit.minutesToUnit(minutes: 1.0, unit: .milliseconds))
            expectEquals(1.0 * (1 * 60), TimeUnit.minutesToUnit(minutes: 1.0, unit: .seconds))
            expectEquals(1.0 * (1), TimeUnit.minutesToUnit(minutes: 1.0, unit: .minutes))
            expectEquals(1.0 / (1 * 60), TimeUnit.minutesToUnit(minutes: 1.0, unit: .hours))
            expectEquals(1.0 / (1 * 60 * 24), TimeUnit.minutesToUnit(minutes: 1.0, unit: .days))
        }

        it("hours") {
            expectEquals(1.0 * (1 * 1_000 * 1_000 * 1_000 * 60 * 60), TimeUnit.hoursToUnit(hours: 1.0, unit: .nanoseconds))
            expectEquals(1.0 * (1 * 1_000 * 1_000 * 60 * 60), TimeUnit.hoursToUnit(hours: 1.0, unit: .microseconds))
            expectEquals(1.0 * (1 * 1_000 * 60 * 60), TimeUnit.hoursToUnit(hours: 1.0, unit: .milliseconds))
            expectEquals(1.0 * (1 * 60 * 60), TimeUnit.hoursToUnit(hours: 1.0, unit: .seconds))
            expectEquals(1.0 * (1 * 60), TimeUnit.hoursToUnit(hours: 1.0, unit: .minutes))
            expectEquals(1.0 * (1), TimeUnit.hoursToUnit(hours: 1.0, unit: .hours))
            expectEquals(1.0 / (1 * 24), TimeUnit.hoursToUnit(hours: 1.0, unit: .days))
        }

        it("days") {
            expectEquals(1.0 * (1 * 1_000 * 1_000 * 1_000 * 60 * 60 * 24), TimeUnit.daysToUnit(days: 1.0, unit: .nanoseconds))
            expectEquals(1.0 * (1 * 1_000 * 1_000 * 60 * 60 * 24), TimeUnit.daysToUnit(days: 1.0, unit: .microseconds))
            expectEquals(1.0 * (1 * 1_000 * 60 * 60 * 24), TimeUnit.daysToUnit(days: 1.0, unit: .milliseconds))
            expectEquals(1.0 * (1 * 60 * 60 * 24), TimeUnit.daysToUnit(days: 1.0, unit: .seconds))
            expectEquals(1.0 * (1 * 60 * 24), TimeUnit.daysToUnit(days: 1.0, unit: .minutes))
            expectEquals(1.0 * (1 * 24), TimeUnit.daysToUnit(days: 1.0, unit: .hours))
            expectEquals(1.0 * (1), TimeUnit.daysToUnit(days: 1.0, unit: .days))
        }
    }
}
