import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class TimerSpecs: QuickSpec {
    override func spec() {

        it("TimerBuilder") {
            let timer = TimerBuilder(name: "timer")
                .tags(["a": "1", "b": "2"])
                .tag("c", "3")
                .register(registry: CumulativeMetricRegistry())

            expect(timer.id.name) == "timer"
            expect(timer.id.tags) == ["a": "1", "b": "2", "c": "3"]
            expect(timer.id.type) == .timer
        }

        it("TimerSample") {

            class ClockStub: Clock {


                private var _tick: UInt64 = 100


                func now() -> Date {
                    Date()
                }

                func currentMillis() -> Int64 {
                    0
                }

                func tick() -> UInt64 {
                    let current = _tick
                    _tick = _tick + 42
                    return current
                }
            }

            let sample = TimerSample.start(clock: ClockStub())
            let timer = CumulativeMetricRegistry().timer(name: "timer")
            sample.stop(timer: timer)

            expect(timer.totalTime(unit: .nanoseconds)) == 42.0
        }
    }
}