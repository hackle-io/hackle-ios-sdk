import Foundation
import Nimble
import Quick
@testable import Hackle

class CompositeSynchronizerSpecs: QuickSpec {
    override class func spec() {

        var workspaceSynchronizer: MockSynchronizer!
        var cohortSynchronizer: MockSynchronizer!
        var sut: CompositeSynchronizer!

        beforeEach {
            workspaceSynchronizer = MockSynchronizer()
            cohortSynchronizer = MockSynchronizer()
            sut = CompositeSynchronizer()
            sut.add(synchronizer: workspaceSynchronizer)
            sut.add(synchronizer: cohortSynchronizer)
        }

        it("sync") {
            // given
            var count = 0
            // when
            awaitCompletion {
                try? await sut.sync()
                count += 1
            }

            // then
            expect(count) == 1
            verify(exactly: 1) {
                workspaceSynchronizer.syncMock
            }
            verify(exactly: 1) {
                cohortSynchronizer.syncMock
            }
        }

        it("child들을 동시에 dispatch한다 (결정적 병렬성 증명)") {
            // given: 두 child가 모두 sync()에 진입해야만 통과하는 배리어(count 2)
            let barrier = Barrier(count: 2)
            let parallelSut = CompositeSynchronizer()
            let a = BarrierSynchronizer(barrier: barrier)
            let b = BarrierSynchronizer(barrier: barrier)
            parallelSut.add(synchronizer: a)
            parallelSut.add(synchronizer: b)

            // when: 순차 await로 dispatch하면 첫 child가 배리어에서 영구 대기 → 타임아웃 실패.
            //       TaskGroup 팬아웃이면 둘 다 진입 → 배리어 통과 → 완료.
            var completed = false
            awaitCompletion(timeout: .seconds(2)) {
                try await parallelSut.sync()
                completed = true
            }

            // then
            expect(completed) == true
            expect(a.synced) == true
            expect(b.synced) == true
        }

        it("safe") {
            // given
            let registry = CumulativeMetricRegistry()
            let counter = registry.counter(name: "workspace")

            every(workspaceSynchronizer.syncMock).answers { _ in
                Thread.sleep(forTimeInterval: 0.1)
                counter.increment()
            }

            every(cohortSynchronizer.syncMock).answers { _ in
                Thread.sleep(forTimeInterval: 0.05)
                throw HackleError.error("fail")
            }

            // when
            var thrown: Error?
            awaitCompletion {
                do {
                    try await sut.sync()
                } catch {
                    thrown = error
                }
            }

            // then
            expect(thrown).to(beNil())
            expect(counter.count()) == 1
        }
    }
}

