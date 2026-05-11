import Foundation
import Quick
import Nimble
@testable import Hackle


/// `AtomicReference` 의 동시 접근 race 회귀용 stress 스펙.
/// Thread Sanitizer 환경에서 실행해 access race 가 보고되지 않는지 검증한다.
class AtomicReferenceConcurrencySpecs: QuickSpec {
    override func spec() {

        it("concurrent get / set / getAndSet") {
            let ref = AtomicReference<Int>(value: 0)

            let readerCount = 4
            let writerCount = 4
            let swapperCount = 2
            let iterations = 20_000

            let group = DispatchGroup()

            for _ in 0..<readerCount {
                DispatchQueue.global().async(group: group) {
                    for _ in 0..<iterations {
                        _ = ref.get()
                    }
                }
            }

            for w in 0..<writerCount {
                DispatchQueue.global().async(group: group) {
                    for i in 0..<iterations {
                        ref.set(newValue: w * iterations + i)
                    }
                }
            }

            for _ in 0..<swapperCount {
                DispatchQueue.global().async(group: group) {
                    for i in 0..<iterations {
                        _ = ref.getAndSet(newValue: i)
                    }
                }
            }

            group.wait()
        }

        it("compareAndSet 으로 monotonic 카운터 동작") {
            // race-free 보장: N 개 스레드가 각자 increment 를 시도하고 최종 합이 정확히 일치하면 OK
            let ref = AtomicReference<Int>(value: 0)
            let workerCount = 8
            let perWorker = 5_000

            let group = DispatchGroup()
            for _ in 0..<workerCount {
                DispatchQueue.global().async(group: group) {
                    for _ in 0..<perWorker {
                        while true {
                            let current = ref.get()
                            if ref.compareAndSet(expect: current, update: current + 1) {
                                break
                            }
                        }
                    }
                }
            }

            group.wait()
            expect(ref.get()) == workerCount * perWorker
        }

        it("getAndSet 호출 횟수 합산 정합성") {
            // 각 스레드가 자신만 알 수 있는 값을 set 하고 직전 값을 받아 누적.
            // 모든 스레드의 누적 + 마지막 잔존값 = 모든 입력의 총합 이어야 한다.
            let ref = AtomicReference<Int>(value: 0)
            let workerCount = 4
            let perWorker = 5_000

            let group = DispatchGroup()
            let accumulatedLock = NSLock()
            var accumulated = 0

            for w in 0..<workerCount {
                DispatchQueue.global().async(group: group) {
                    var localSum = 0
                    for i in 1...perWorker {
                        let value = w * perWorker + i
                        let previous = ref.getAndSet(newValue: value)
                        localSum += previous
                    }
                    accumulatedLock.lock()
                    accumulated += localSum
                    accumulatedLock.unlock()
                }
            }

            group.wait()

            let finalValue = ref.get()
            let totalInput = (0..<workerCount).reduce(0) { sum, w in
                sum + (1...perWorker).reduce(0) { $0 + (w * perWorker + $1) }
            }

            // 초기값(0) + 모든 push 한 값들의 합 = (모든 worker 가 받아간 직전값들의 합) + 최종 잔존값
            expect(accumulated + finalValue) == totalInput
        }
    }
}
