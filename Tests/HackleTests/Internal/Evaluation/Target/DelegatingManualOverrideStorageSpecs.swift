import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DelegatingManualOverrideStorageSpecs: QuickSpec {
    override func spec() {

        it("empty storage") {
            let sut = DelegatingManualOverrideStorage(storages: [])
            let actual = sut.get(experiment: MockExperiment(), user: HackleUser.builder().build())
            expect(actual).to(beNil())
        }

        it("first match") {
            let variation = MockVariation()
            let storage = ManualOverrideStorageStub(returns: [
                nil,
                nil,
                nil,
                variation,
                nil
            ])
            let sut = DelegatingManualOverrideStorage(storages: [storage, storage, storage, storage, storage])

            let actual = sut.get(experiment: MockExperiment(), user: HackleUser.builder().build())

            expect(actual).to(beIdenticalTo(variation))
            expect(storage.count) == 4
        }

        it("not match") {
            let storage = ManualOverrideStorageStub(returns: [
                nil,
                nil,
                nil,
                nil,
                nil
            ])
            let sut = DelegatingManualOverrideStorage(storages: [storage, storage, storage, storage, storage])

            let actual = sut.get(experiment: MockExperiment(), user: HackleUser.builder().build())

            expect(actual).to(beNil())
            expect(storage.count) == 5
        }
    }

    class ManualOverrideStorageStub: ManualOverrideStorage {
        let returns: [Variation?]
        var count = 0

        init(returns: [Variation?]) {
            self.returns = returns
        }

        func get(experiment: Experiment, user: HackleUser) -> Variation? {
            let variation = returns[count]
            count = count + 1
            return variation
        }
    }
}