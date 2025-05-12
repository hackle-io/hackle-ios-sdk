import Foundation
import Nimble
import Quick
@testable import Hackle

class CompositeSynchronizerSpecs: QuickSpec {
    override func spec() {

        var workspaceSynchronizer: MockSynchronizer!
        var cohortSynchronizer: MockSynchronizer!
        var sut: CompositeSynchronizer!

        beforeEach {
            workspaceSynchronizer = MockSynchronizer()
            cohortSynchronizer = MockSynchronizer()
            sut = CompositeSynchronizer(dispatchQueue: DispatchQueue(label: "test", attributes: .concurrent))
            sut.add(synchronizer: workspaceSynchronizer)
            sut.add(synchronizer: cohortSynchronizer)
        }

        it("sync") {
            // given
            var count = 0
            // when
            sut.sync { _ in
                count += 1
            }
            Thread.sleep(forTimeInterval: 0.1)

            // then
            expect(count) == 1
            verify(exactly: 1) {
                workspaceSynchronizer.syncMock
            }
            verify(exactly: 1) {
                cohortSynchronizer.syncMock
            }
        }

        it("async") {
            // given
            every(workspaceSynchronizer.syncMock).answers { completion in
                Thread.sleep(forTimeInterval: 0.1)
                completion(.success(()))
            }
            every(cohortSynchronizer.syncMock).answers { completion in
                Thread.sleep(forTimeInterval: 0.1)
                completion(.success(()))
            }
            var count = 0

            // when
            sut.sync {
                count += 1
            }
            Thread.sleep(forTimeInterval: 0.15)

            // then
            expect(count) == 1
        }

        it("safe") {
            // given
            let registry = CumulativeMetricRegistry()
            let counter = registry.counter(name: "workspace")

            every(workspaceSynchronizer.syncMock).answers { completion in
                Thread.sleep(forTimeInterval: 0.1)
                counter.increment()
                completion(.success(()))
            }

            every(cohortSynchronizer.syncMock).answers { completion in
                Thread.sleep(forTimeInterval: 0.05)
                completion(.failure(HackleError.error("fail")))
            }

            // when
            var actual: Result<Void, Error>!
            sut.sync { result in
                actual = result
            }
            Thread.sleep(forTimeInterval: 0.15)

            // then
            try actual.get()
            expect(counter.count()) == 1
        }
    }
}

