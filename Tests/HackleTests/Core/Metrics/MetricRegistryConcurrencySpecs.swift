import Foundation
import Quick
import Nimble
@testable import Hackle


/// 메트릭 레지스트리의 동시 접근 race 재현용 stress 스펙.
///
/// Production 크래시 컨텍스트:
///  - `MonitoringMetricRegistry.doFlush()` 가 `httpQueue`에서 `metrics` getter 호출 (read)
///  - `URLSession` delegate 큐에서 들어오는 HTTP 응답이 `ApiCallMetrics.record` →
///    `Metrics.timer(name:tags:)` → `_metrics[id] = newMetric` 호출 (write)
///
/// 두 작업이 Swift `Dictionary` 에 동시 접근하면서 buffer rehash / ARC race 로 크래시.
/// 본 스펙은 동일한 패턴을 강제로 재현해 Thread Sanitizer 가 race 를 보고하도록 한다.
///
/// 실행:
/// ```
/// xcodebuild test \
///     -scheme Hackle \
///     -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
///     -enableThreadSanitizer YES \
///     -only-testing:HackleTests/MetricRegistryConcurrencySpecs \
///     CODE_SIGNING_ALLOWED=NO
/// ```
class MetricRegistryConcurrencySpecs: QuickSpec {
    override func spec() {

        beforeEach {
            Metrics.clear()
        }

        it("MetricRegistry: concurrent timer creation vs metrics iteration") {
            // 실제 production 의 doFlush vs record 패턴을 모사한다.
            // - writer: 매번 새로운 tag 조합으로 timer 생성 → MetricRegistry._metrics write
            // - reader: globalRegistry.metrics getter 반복 호출 → _metrics read (lock 없음)
            let cumulative = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: cumulative)

            let writerCount = 8
            let writerIterations = 2_000
            let readerIterations = 20_000

            let group = DispatchGroup()

            for w in 0..<writerCount {
                DispatchQueue.global().async(group: group) {
                    for i in 0..<writerIterations {
                        let tags = ["w": "\(w)", "i": "\(i)"]
                        let timer = Metrics.timer(name: "stress.api", tags: tags)
                        timer.record(amount: Double(i), unit: .nanoseconds)
                    }
                }
            }

            DispatchQueue.global().async(group: group) {
                for _ in 0..<readerIterations {
                    let snapshot = Metrics.globalRegistry.metrics
                    _ = snapshot.count
                }
            }

            group.wait()
        }

        it("DelegatingTimer: concurrent record vs add(registry:)") {
            // DelegatingTimer._timers race 재현.
            // - writer: add(registry:) 가 _timers 에 write
            // - reader: record(amount:unit:) 가 timers getter 로 _timers read (lock 없음)
            let delegating = DelegatingMetricRegistry()
            let timer = delegating.timer(name: "stress.timer")

            let recordIterations = 50_000
            let addIterations = 500

            let group = DispatchGroup()

            DispatchQueue.global().async(group: group) {
                for _ in 0..<recordIterations {
                    timer.record(amount: 1, unit: .nanoseconds)
                }
            }

            DispatchQueue.global().async(group: group) {
                for _ in 0..<addIterations {
                    delegating.add(registry: CumulativeMetricRegistry())
                }
            }

            group.wait()
        }

        it("DelegatingCounter: concurrent increment vs add(registry:)") {
            // DelegatingCounter._counters race 재현. DelegatingTimer 와 동일 패턴.
            let delegating = DelegatingMetricRegistry()
            let counter = delegating.counter(name: "stress.counter")

            let incrementIterations = 50_000
            let addIterations = 500

            let group = DispatchGroup()

            DispatchQueue.global().async(group: group) {
                for _ in 0..<incrementIterations {
                    counter.increment(1)
                }
            }

            DispatchQueue.global().async(group: group) {
                for _ in 0..<addIterations {
                    delegating.add(registry: CumulativeMetricRegistry())
                }
            }

            group.wait()
        }
    }
}
