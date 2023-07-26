import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultInAppMessageImpressionStorageSpecs: QuickSpec {
    override func spec() {
        var repository: KeyValueRepository!
        var sut: DefaultInAppMessageImpressionStorage!

        beforeEach {
            repository = MemoryKeyValueRepository()
            sut = DefaultInAppMessageImpressionStorage(keyValueRepository: repository)
        }

        it("get and set") {
            let inAppMessage = InAppMessage.create(id: 42)
            let impression = InAppMessageImpression(identifiers: ["a": "b"], timestamp: 4242)

            expect(try sut.get(inAppMessage: inAppMessage).count) == 0

            try sut.set(inAppMessage: inAppMessage, impressions: [impression])
            expect(repository.getData(key: "42")).toNot(beNil())

            expect(try sut.get(inAppMessage: inAppMessage).count) == 1
            expect(try sut.get(inAppMessage: inAppMessage)[0].timestamp) == 4242
        }
    }
}
