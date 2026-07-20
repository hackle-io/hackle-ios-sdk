import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessagePresentProcessorSpecs: AsyncSpec {
    override class func spec() {

        it("process") {
            // given
            let presenter = MockInAppMessagePresenter()
            let recorder = MockInAppMessageRecorder()
            let sut = DefaultInAppMessagePresentProcessor(
                presenter: presenter,
                recorder: recorder
            )
            every(presenter.presentMock).returns(true)

            let request = InAppMessageEntity.presentRequest(
                dispatchId: "111"
            )

            // when
            let actual = try await sut.process(request: request)

            // then
            expect(actual.dispatchId) == "111"
            expect(actual.context.dispatchId) == "111"
            verify(exactly: 1) {
                presenter.presentMock
            }
            verify(exactly: 1) {
                recorder.recordMock
            }
        }

        it("노출되지 않은 메시지는 impression을 기록하지 않는다") {
            // given
            let presenter = MockInAppMessagePresenter()
            let recorder = MockInAppMessageRecorder()
            let sut = DefaultInAppMessagePresentProcessor(
                presenter: presenter,
                recorder: recorder
            )
            every(presenter.presentMock).returns(false)

            let request = InAppMessageEntity.presentRequest(
                dispatchId: "111"
            )

            // when
            let actual = try await sut.process(request: request)

            // then
            expect(actual.dispatchId) == "111"
            verify(exactly: 1) {
                presenter.presentMock
            }
            verify(exactly: 0) {
                recorder.recordMock
            }
        }
    }
}
