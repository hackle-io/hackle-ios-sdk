import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessagePresentProcessorSpecs: QuickSpec {
    override func spec() {

        var presenter: MockInAppMessagePresenter!
        var recorder: MockInAppMessageRecorder!
        var sut: DefaultInAppMessagePresentProcessor!

        beforeEach {
            presenter = MockInAppMessagePresenter()
            recorder = MockInAppMessageRecorder()
            sut = DefaultInAppMessagePresentProcessor(
                presenter: presenter,
                recorder: recorder
            )
        }

        it("process") {
            // given
            let request = InAppMessage.presentRequest(
                dispatchId: "111"
            )

            // when
            let actual = try sut.process(request: request)

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
    }
}
