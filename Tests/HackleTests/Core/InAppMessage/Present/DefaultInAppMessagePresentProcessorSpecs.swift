import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessagePresentProcessorSpecs: AsyncSpec {
    override class func spec() {

        var coreQueue: DispatchQueue!
        var presenter: MockInAppMessagePresenter!
        var recorder: MockInAppMessageRecorder!
        var sut: DefaultInAppMessagePresentProcessor!

        beforeEach {
            coreQueue = DispatchQueue(label: "test.CoreQueue")
            presenter = MockInAppMessagePresenter()
            recorder = MockInAppMessageRecorder()
            sut = DefaultInAppMessagePresentProcessor(
                coreQueue: coreQueue,
                presenter: presenter,
                recorder: recorder
            )
        }

        it("present 후 응답 코드와 함께 record를 호출한다") {
            // given
            let request = InAppMessageEntity.presentRequest(dispatchId: "111")
            every(presenter.presentMock).answers { context in
                InAppMessagePresentResponse.of(code: .present, context: context)
            }

            // when
            let actual = await sut.process(request: request)

            // then
            expect(actual.code) == InAppMessagePresentResponse.Code.present
            expect(actual.context.dispatchId) == "111"
            verify(exactly: 1) {
                presenter.presentMock
            }
            verify(exactly: 1) {
                recorder.recordMock
            }
        }

        it("record에는 present가 반환한 응답이 그대로 전달된다") {
            // given
            let request = InAppMessageEntity.presentRequest(dispatchId: "222")
            every(presenter.presentMock).answers { context in
                InAppMessagePresentResponse.of(code: .alreadyPresented, context: context)
            }

            // when
            let actual = await sut.process(request: request)

            // then
            expect(actual.code) == InAppMessagePresentResponse.Code.alreadyPresented
            verify(exactly: 1) {
                recorder.recordMock
            }
        }
    }
}
