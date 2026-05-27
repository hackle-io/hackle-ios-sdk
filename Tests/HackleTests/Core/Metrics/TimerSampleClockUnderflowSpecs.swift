import Foundation
import Quick
import Nimble
@testable import Hackle


/// Regression guard for the metric crash (EXC_BREAKPOINT / SIGTRAP).
///
/// Background: a `Clock` whose `tick()` is wall-clock based (e.g. NTP step-adjust,
/// user changing system time) can return a smaller value on the second call.
/// `Double(clock.tick() - startTick)` then performs a `UInt64` subtraction that
/// traps with "Swift runtime failure: arithmetic overflow".
///
/// `TimerSample.stop` must tolerate that scenario without trapping.
class TimerSampleClockUnderflowSpecs: QuickSpec {
    override class func spec() {

        describe("TimerSample.stop with a backwards-moving clock") {

            it("does not trap and skips recording when stop tick < start tick") {
                // First tick: T0. Second tick: T0 - 500ms (clock moved backwards).
                let backwards = BackwardsClock(
                    ticks: [
                        1_000_000_000_000,
                        999_500_000_000
                    ]
                )

                let sample = TimerSample.start(clock: backwards)
                let timer = CumulativeMetricRegistry().timer(name: "underflow.repro")

                sample.stop(timer: timer)

                expect(timer.count()) == 0
            }

            it("records zero duration when stop tick == start tick") {
                let same = BackwardsClock(ticks: [1_000, 1_000])

                let sample = TimerSample.start(clock: same)
                let timer = CumulativeMetricRegistry().timer(name: "equal.tick")

                sample.stop(timer: timer)

                expect(timer.count()) == 1
                expect(timer.totalTime(unit: .nanoseconds)) == 0.0
            }
        }
    }
}

private final class BackwardsClock: Clock {
    private var queue: [UInt64]

    init(ticks: [UInt64]) {
        self.queue = ticks
    }

    func now() -> Date { Date() }
    func currentMillis() -> Int64 { 0 }

    func tick() -> UInt64 {
        precondition(!queue.isEmpty, "BackwardsClock ran out of scripted ticks")
        return queue.removeFirst()
    }
}
