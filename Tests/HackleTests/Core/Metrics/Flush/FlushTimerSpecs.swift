import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class FlushTimerSpecs: QuickSpec {
    override func spec() {

        it("record, flush") {
            let flushTimer = FlushTimer(id: MetricId(name: UUID().uuidString, tags: [:], type: .timer))
            for i in 1...100 {
                flushTimer.record(amount: Double(i), unit: .milliseconds)
            }

            expect(flushTimer.count()) == 100
            expect(flushTimer.totalTime(unit: .milliseconds)) == 5050.0
            expect(flushTimer.max(unit: .milliseconds)) == 100.0
            expect(flushTimer.mean(unit: .milliseconds)) == 50.5

            let measurements = flushTimer.flush().measure()
            expect(measurements[0].value) == 100.0
            expect(measurements[1].value) == 5050.0
            expect(measurements[2].value) == 100.0
            expect(measurements[3].value) == 50.5


            expect(flushTimer.count()) == 0
            expect(flushTimer.totalTime(unit: .milliseconds)) == 0.0
            expect(flushTimer.max(unit: .milliseconds)) == 0.0
            expect(flushTimer.mean(unit: .milliseconds)) == 0.0

            flushTimer.record(amount: 42, unit: .milliseconds)
            expect(measurements[0].value) == 100.0
            expect(measurements[1].value) == 5050.0
            expect(measurements[2].value) == 100.0
            expect(measurements[3].value) == 50.5
        }

        it("concurrency") {
            let timer = FlushTimer(id: MetricId(name: UUID().uuidString, tags: [:], type: .timer))

            var flushed = [HackleTimer?](repeating: nil, count: 5001)
            let q = DispatchQueue.concurrent()
            for i in 0..<10000 {
                q.async {
                    if i % 2 == 0 {
                        timer.record(amount: Double(i + 1), unit: .nanoseconds)
                    } else {
                        flushed[i / 2] = (timer.flush() as! HackleTimer)
                    }
                }
            }
            q.await()
            flushed.append((timer.flush() as! HackleTimer))

            let count = flushed.sumOf { timer in
                timer?.count() ?? 0
            }
            let totalTime = flushed.sumOf { timer in
                timer?.totalTime(unit: .nanoseconds) ?? 0.0
            }
            expect(count) == 5000
            expect(totalTime) == 25000000.0
        }

        it("measure") {
            let timer = FlushTimer(id: MetricId(name: UUID().uuidString, tags: [:], type: .timer))
            timer.record(amount: 42, unit: .milliseconds)

            let measurements = timer.measure()
            expect(measurements.count) == 4
            expect(measurements[0].value) == 1.0
            expect(measurements[1].value) == 42.0
            expect(measurements[2].value) == 42.0
            expect(measurements[3].value) == 42.0

            timer.flush()
            expect(measurements[0].value) == 0.0
            expect(measurements[1].value) == 0.0
            expect(measurements[2].value) == 0.0
            expect(measurements[3].value) == 0.0
        }
    }
}
