import Foundation
import Quick
import Nimble
@testable import Hackle


/// Stress spec for `AtomicReference` concurrent access race regression.
/// Run under Thread Sanitizer to verify no access race is reported.
class AtomicReferenceRaceSpecs: QuickSpec {
    override class func spec() {

        it("concurrent get / set / getAndSet does not corrupt") {
            let ref = AtomicReference<Int>(value: 0)

            let readerCount = 4
            let writerCount = 4
            let swapperCount = 2
            let iterations = 20_000

            let group = DispatchGroup()

            for _ in 0..<readerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for _ in 0..<iterations {
                        _ = ref.get()
                    }
                }
            }

            for w in 0..<writerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<iterations {
                        ref.set(newValue: w * iterations + i)
                    }
                }
            }

            for _ in 0..<swapperCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<iterations {
                        _ = ref.getAndSet(newValue: i)
                    }
                }
            }

            group.wait()

            let baseline = ref.get()
            ref.set(newValue: baseline + 1)
            expect(ref.get()) == baseline + 1
        }

        it("compareAndSet provides monotonic counter behavior") {
            // Race-free guarantee: N threads each attempt increments and the final sum matches exactly.
            let ref = AtomicReference<Int>(value: 0)
            let workerCount = 8
            let perWorker = 5_000

            let group = DispatchGroup()
            for _ in 0..<workerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
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

        it("getAndSet call total matches across writers") {
            // Each thread sets a value only it knows, accumulating the previous value it received.
            // The sum of all accumulated previous values plus the final residual value must equal
            // the total of all inputs.
            let ref = AtomicReference<Int>(value: 0)
            let workerCount = 4
            let perWorker = 5_000

            let group = DispatchGroup()
            let accumulatedLock = NSLock()
            var accumulated = 0

            for w in 0..<workerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
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

            // initial value (0) + all pushed values = sum of all previous values received + final residual
            expect(accumulated + finalValue) == totalInput
        }
    }
}
