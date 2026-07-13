import Foundation
import Quick
import Nimble
@testable import Hackle

/// Regression spec for `DefaultInAppMessageRecorder`'s impression record data race.
/// Run under Thread Sanitizer to verify no access race is reported.
///
/// The recorder/storage are intentionally shared across GCD queues so the get→append→trim→set
/// read-modify-write is exercised concurrently. The compiler cannot prove that sharing is safe,
/// so the shared locals are marked `nonisolated(unsafe)` — the safety is provided at runtime by
/// the `ReadWriteLock` inside `DefaultInAppMessageRecorder`, which this spec exists to guard.
class DefaultInAppMessageRecorderRaceSpecs: QuickSpec {
    override class func spec() {

        it("동시에 100건을 기록해도 유실 없이 모두 저장된다") {
            nonisolated(unsafe) let storage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
            nonisolated(unsafe) let sut = DefaultInAppMessageRecorder(storage: storage)
            let inAppMessage = InAppMessageEntity.create(id: 42)
            nonisolated(unsafe) let request = InAppMessageEntity.presentRequest(inAppMessage: inAppMessage)
            nonisolated(unsafe) let response = InAppMessageEntity.presentResponse()

            let producerCount = 10
            let perProducer = 10

            let group = DispatchGroup()
            for _ in 0..<producerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for _ in 0..<perProducer {
                        sut.record(request: request, response: response)
                    }
                }
            }
            group.wait()

            expect(try storage.get(inAppMessage: inAppMessage).count) == 100
        }

        it("동시에 STORE_MAX_SIZE를 초과 기록해도 정확히 100건으로 유지된다") {
            nonisolated(unsafe) let storage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
            nonisolated(unsafe) let sut = DefaultInAppMessageRecorder(storage: storage)
            let inAppMessage = InAppMessageEntity.create(id: 42)
            nonisolated(unsafe) let request = InAppMessageEntity.presentRequest(inAppMessage: inAppMessage)
            nonisolated(unsafe) let response = InAppMessageEntity.presentResponse()

            let producerCount = 8
            let perProducer = 25

            let group = DispatchGroup()
            for _ in 0..<producerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for _ in 0..<perProducer {
                        sut.record(request: request, response: response)
                    }
                }
            }
            group.wait()

            expect(try storage.get(inAppMessage: inAppMessage).count) == 100
        }
    }
}
