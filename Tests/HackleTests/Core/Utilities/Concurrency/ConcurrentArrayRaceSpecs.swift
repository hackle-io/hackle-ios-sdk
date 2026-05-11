import Foundation
import Quick
import Nimble
@testable import Hackle


/// Stress spec for `ConcurrentArray` concurrent access race regression.
/// Run under Thread Sanitizer to verify no access race is reported.
class ConcurrentArrayRaceSpecs: QuickSpec {
    override func spec() {

        it("concurrent add / take / size") {
            let array = ConcurrentArray<Int>()

            let producerCount = 4
            let consumerCount = 4
            let observerCount = 2
            let producerIterations = 5_000
            let consumerIterations = 5_000
            let observerIterations = 20_000
            let totalAdds = producerCount * producerIterations

            let takenLock = NSLock()
            var takenCount = 0

            let group = DispatchGroup()

            for p in 0..<producerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<producerIterations {
                        array.add(p * producerIterations + i)
                    }
                }
            }

            for _ in 0..<consumerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    var localTaken = 0
                    for _ in 0..<consumerIterations {
                        if array.take() != nil {
                            localTaken += 1
                        }
                    }
                    takenLock.lock()
                    takenCount += localTaken
                    takenLock.unlock()
                }
            }

            for _ in 0..<observerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for _ in 0..<observerIterations {
                        _ = array.size
                        _ = array.isEmpty
                    }
                }
            }

            group.wait()

            expect(array.size + takenCount) == totalAdds
        }

        it("concurrent add / takeAll") {
            let array = ConcurrentArray<Int>()

            let producerCount = 6
            let drainerCount = 2
            let producerIterations = 5_000
            let drainerIterations = 5_000
            let totalAdds = producerCount * producerIterations

            let drainedLock = NSLock()
            var drainedTotal = 0

            let group = DispatchGroup()

            for p in 0..<producerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<producerIterations {
                        array.add(p * producerIterations + i)
                    }
                }
            }

            for _ in 0..<drainerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    var localDrained = 0
                    for _ in 0..<drainerIterations {
                        localDrained += array.takeAll().count
                    }
                    drainedLock.lock()
                    drainedTotal += localDrained
                    drainedLock.unlock()
                }
            }

            group.wait()

            expect(drainedTotal + array.size) == totalAdds
        }

        it("all producers can drain their added items exactly once via single consumer") {
            // Functional correctness check: with no race, total add count = total take count.
            let array = ConcurrentArray<Int>()
            let producerCount = 4
            let perProducer = 2_000
            let totalAdds = producerCount * perProducer

            let producers = DispatchGroup()
            for p in 0..<producerCount {
                DispatchQueue.global(qos: .utility).async(group: producers) {
                    for i in 0..<perProducer {
                        array.add(p * perProducer + i)
                    }
                }
            }

            producers.wait()

            var consumedCount = 0
            while array.take() != nil {
                consumedCount += 1
            }

            expect(consumedCount) == totalAdds
            expect(array.isEmpty) == true
        }

        it("concurrent producers and consumers — added items are consumed at most once") {
            let array = ConcurrentArray<Int>()
            let producerCount = 4
            let consumerCount = 4
            let perProducer = 2_000
            let perConsumer = 2_000
            let totalAdds = producerCount * perProducer

            let consumedLock = NSLock()
            var consumedCount = 0

            let group = DispatchGroup()

            for p in 0..<producerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<perProducer {
                        array.add(p * perProducer + i)
                    }
                }
            }

            for _ in 0..<consumerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    var localConsumed = 0
                    for _ in 0..<perConsumer {
                        if array.take() != nil {
                            localConsumed += 1
                        }
                    }
                    consumedLock.lock()
                    consumedCount += localConsumed
                    consumedLock.unlock()
                }
            }

            group.wait()

            expect(consumedCount + array.size) == totalAdds
        }
    }
}
