import Foundation
import Nimble
import Quick
@testable import Hackle

class SynchronizerSpecs: QuickSpec {
    override func spec() {
        describe("SynchronizerExtensions") {
            describe("Synchronizer.sync(() -> ())") {
                it("success") {
                    let counter = CumulativeMetricRegistry().counter(name: "counter")
                    let sut = SynchronizerStub(.success(()))
                    sut.sync {
                        counter.increment()
                    }
                    expect(counter.count()) == 1
                }

                it("failure") {
                    let counter = CumulativeMetricRegistry().counter(name: "counter")
                    let sut = SynchronizerStub(.failure(HackleError.error("fail")))
                    sut.sync {
                        counter.increment()
                    }
                    expect(counter.count()) == 1
                }
            }
        }
    }
}

class SynchronizerStub: Synchronizer {

    private let result: Result<Void, Error>

    init(_ result: Result<(), Error>) {
        self.result = result
    }

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        completion(result)
    }
}
