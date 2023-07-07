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
        }

        it("nanos") {
            expectEquals(1.0 * (1), TimeUnit.nanosToUnit(nanos: 1.0, unit: .nanoseconds))
            expectEquals(1.0 / (1 * 1_000), TimeUnit.nanosToUnit(nanos: 1.0, unit: .microseconds))
            expectEquals(1.0 / (1 * 1_000 * 1_000), TimeUnit.nanosToUnit(nanos: 1.0, unit: .milliseconds))
            expectEquals(1.0 / (1 * 1_000 * 1_000 * 1_000), TimeUnit.nanosToUnit(nanos: 1.0, unit: .seconds))
        }

        it("micros") {
            expectEquals(1.0 * (1 * 1_000), TimeUnit.microsToUnit(micros: 1.0, unit: .nanoseconds))
            expectEquals(1.0 / (1), TimeUnit.microsToUnit(micros: 1.0, unit: .microseconds))
            expectEquals(1.0 / (1 * 1_000), TimeUnit.microsToUnit(micros: 1.0, unit: .milliseconds))
            expectEquals(1.0 / (1 * 1_000 * 1_000), TimeUnit.microsToUnit(micros: 1.0, unit: .seconds))
        }

        it("millis") {
            expectEquals(1.0 * (1 * 1_000 * 1_000), TimeUnit.millisToUnit(millis: 1.0, unit: .nanoseconds))
            expectEquals(1.0 * (1 * 1_000), TimeUnit.millisToUnit(millis: 1.0, unit: .microseconds))
            expectEquals(1.0 * (1), TimeUnit.millisToUnit(millis: 1.0, unit: .milliseconds))
            expectEquals(1.0 / (1 * 1_000), TimeUnit.millisToUnit(millis: 1.0, unit: .seconds))
        }

        it("seconds") {
            expectEquals(1.0 * (1 * 1_000 * 1_000 * 1_000), TimeUnit.secondsToUnit(seconds: 1.0, unit: .nanoseconds))
            expectEquals(1.0 * (1 * 1_000 * 1_000), TimeUnit.secondsToUnit(seconds: 1.0, unit: .microseconds))
            expectEquals(1.0 * (1 * 1_000), TimeUnit.secondsToUnit(seconds: 1.0, unit: .milliseconds))
            expectEquals(1.0 * (1), TimeUnit.secondsToUnit(seconds: 1.0, unit: .seconds))
        }
    }
}
