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
            waitUntil { done in
                Task {
                    try? await sut.sync()
                    count += 1
                    done()
                }
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

        it("async") {
            // given
            every(workspaceSynchronizer.syncMock).answers { _ in
                Thread.sleep(forTimeInterval: 0.1)
            }
            every(cohortSynchronizer.syncMock).answers { _ in
                Thread.sleep(forTimeInterval: 0.1)
            }
            var count = 0
            var elapsed: TimeInterval = 0

            // when
            waitUntil(timeout: .seconds(1)) { done in
                Task {
                    let start = Date()
                    try? await sut.sync()
                    elapsed = Date().timeIntervalSince(start)
                    count += 1
                    done()
                }
            }

            // then
            expect(count) == 1
            expect(elapsed) < 0.19
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
            waitUntil { done in
                Task {
                    do {
                        try await sut.sync()
                    } catch {
                        thrown = error
                    }
                    done()
                }
            }

            // then
            expect(thrown).to(beNil())
            expect(counter.count()) == 1
        }
    }
}

