import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessagePresentProcessorSpecs: QuickSpec {
    override func spec() {

        var contextResolver: MockInAppMessagePresentationContextResolver!
        var presenter: MockInAppMessagePresenter!
        var recorder: MockInAppMessageRecorder!
        var sut: DefaultInAppMessagePresentProcessor!

        beforeEach {
            contextResolver = MockInAppMessagePresentationContextResolver()
            presenter = MockInAppMessagePresenter()
            recorder = MockInAppMessageRecorder()
            sut = DefaultInAppMessagePresentProcessor(
                contextResolver: contextResolver,
                presenter: presenter,
                recorder: recorder
            )
        }

        it("process") {
            // given
            let request = InAppMessage.presentRequest(
                dispatchId: "111"
            )
            let context = InAppMessage.context()
            every(contextResolver.resolveMock).returns(context)

            // when
            let actual = try sut.process(request: request)

            // then
            expect(actual.dispatchId) == "111"
            expect(actual.context).to(beIdenticalTo(context))
            verify(exactly: 1) {
                presenter.presentMock
            }
            verify(exactly: 1) {
                recorder.recordMock
            }
        }
    }
}
