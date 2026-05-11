import Foundation
import Quick
import Nimble
@testable import Hackle


/// `ConcurrentArray` 의 동시 접근 race 회귀용 stress 스펙.
/// Thread Sanitizer 환경에서 실행해 access race 가 보고되지 않는지 검증한다.
class ConcurrentArrayConcurrencySpecs: QuickSpec {
    override func spec() {

        it("concurrent add / take / size") {
            let array = ConcurrentArray<Int>()

            let producerCount = 4
            let consumerCount = 4
            let observerCount = 2
            let producerIterations = 5_000
            let consumerIterations = 5_000
            let observerIterations = 20_000

            let group = DispatchGroup()

            for p in 0..<producerCount {
                DispatchQueue.global().async(group: group) {
                    for i in 0..<producerIterations {
                        array.add(p * producerIterations + i)
                    }
                }
            }

            for _ in 0..<consumerCount {
                DispatchQueue.global().async(group: group) {
                    for _ in 0..<consumerIterations {
                        _ = array.take()
                    }
                }
            }

            for _ in 0..<observerCount {
                DispatchQueue.global().async(group: group) {
                    for _ in 0..<observerIterations {
                        _ = array.size
                        _ = array.isEmpty
                    }
                }
            }

            group.wait()
        }

        it("concurrent add / takeAll") {
            let array = ConcurrentArray<Int>()

            let producerCount = 6
            let drainerCount = 2
            let producerIterations = 5_000
            let drainerIterations = 5_000

            let group = DispatchGroup()

            for p in 0..<producerCount {
                DispatchQueue.global().async(group: group) {
                    for i in 0..<producerIterations {
                        array.add(p * producerIterations + i)
                    }
                }
            }

            for _ in 0..<drainerCount {
                DispatchQueue.global().async(group: group) {
                    for _ in 0..<drainerIterations {
                        _ = array.takeAll()
                    }
                }
            }

            group.wait()
        }

        it("producer/consumer 시나리오에서 모든 요소가 정확히 한 번씩 소비된다") {
            // 기능적 정합성 검증: race 없이 동작한다면 전체 add 횟수 = 전체 take 횟수
            let array = ConcurrentArray<Int>()
            let producerCount = 4
            let perProducer = 2_000
            let totalAdds = producerCount * perProducer

            let consumedLock = NSLock()
            var consumedCount = 0

            let producers = DispatchGroup()
            for p in 0..<producerCount {
                DispatchQueue.global().async(group: producers) {
                    for i in 0..<perProducer {
                        array.add(p * perProducer + i)
                    }
                }
            }

            // 모든 producer 완료 후 단일 스레드에서 drain — race-free 검증
            producers.wait()

            while let _ = array.take() {
                consumedLock.lock()
                consumedCount += 1
                consumedLock.unlock()
            }

            expect(consumedCount) == totalAdds
            expect(array.isEmpty) == true
        }
    }
}
