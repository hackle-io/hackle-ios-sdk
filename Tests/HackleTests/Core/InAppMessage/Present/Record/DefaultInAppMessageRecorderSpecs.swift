import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageRecorderSpecs: QuickSpec {
    override class func spec() {

        var storage: InAppMessageImpressionStorage!
        var sut: DefaultInAppMessageRecorder!

        beforeEach {
            storage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
            sut = DefaultInAppMessageRecorder(storage: storage)
        }

        it("when override then do not record") {
            // given
            let inAppMessage = InAppMessageEntity.create()
            let request = InAppMessageEntity.presentRequest(
                inAppMessage: inAppMessage,
                reason: DecisionReason.OVERRIDDEN
            )
            let response = InAppMessageEntity.presentResponse()

            // when
            sut.record(request: request, response: response)

            // then
            let impressions = try storage.get(inAppMessage: inAppMessage)
            expect(impressions.count) == 0
        }

        it("record") {
            // given
            let user = HackleUser.builder()
                .identifier("a", "1")
                .identifier("b", "2")
                .build()
            let inAppMessage = InAppMessageEntity.create(
                id: 42
            )
            let presentationContext = InAppMessageEntity.context(
                inAppMessage: inAppMessage,
                user: user
            )
            let request = InAppMessageEntity.presentRequest(
                inAppMessage: inAppMessage,
                user: user,
                requestedAt: Date(timeIntervalSince1970: 320),
                reason: DecisionReason.IN_APP_MESSAGE_TARGET
            )
            let response = InAppMessageEntity.presentResponse(
                context: presentationContext
            )

            // when
            sut.record(request: request, response: response)

            // then
            let impressions = try storage.get(inAppMessage: inAppMessage)
            expect(impressions.count) == 1
            expect(impressions[0].identifiers) == ["a": "1", "b": "2"]
            expect(impressions[0].timestamp) == 320
        }

        it("when exceed record limit then remove first") {
            let inAppMessage = InAppMessageEntity.create(id: 42)
            let request = InAppMessageEntity.presentRequest(
                inAppMessage: inAppMessage
            )
            let response = InAppMessageEntity.presentResponse()


            for _ in 0..<100 {
                sut.record(request: request, response: response)
            }
            expect(try storage.get(inAppMessage: inAppMessage).count) == 100

            sut.record(request: request, response: response)
            expect(try storage.get(inAppMessage: inAppMessage).count) == 100
        }
    }
}
