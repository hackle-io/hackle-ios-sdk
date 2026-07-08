import Foundation
import Nimble
import Quick
@testable import Hackle

class SynchronizerSpecs: AsyncSpec {
    override class func spec() {
        describe("Synchronizer.safeSync") {
            it("success") {
                let counter = CumulativeMetricRegistry().counter(name: "counter")
                let sut = SynchronizerStub(.success(()))
                await awaitCompletion {
                    await sut.safeSync()
                    counter.increment()
                }
                expect(counter.count()) == 1
            }

            it("failure - 에러를 삼키고 완료된다") {
                let counter = CumulativeMetricRegistry().counter(name: "counter")
                let sut = SynchronizerStub(.failure(HackleError.error("fail")))
                await awaitCompletion {
                    await sut.safeSync()
                    counter.increment()
                }
                expect(counter.count()) == 1
            }
        }
    }
}

class SynchronizerStub: Synchronizer {

    private let result: Result<Void, Error>

    init(_ result: Result<(), Error>) {
        self.result = result
    }

    func sync() async throws {
        try result.get()
    }
}
