import Foundation

protocol InAppMessagePresentProcessor {
    func process(request: InAppMessagePresentRequest) async throws -> InAppMessagePresentResponse
}

class DefaultInAppMessagePresentProcessor: InAppMessagePresentProcessor {

    private let presenter: InAppMessagePresenter
    private let recorder: InAppMessageRecorder

    init(presenter: InAppMessagePresenter, recorder: InAppMessageRecorder) {
        self.presenter = presenter
        self.recorder = recorder
    }

    func process(request: InAppMessagePresentRequest) async throws -> InAppMessagePresentResponse {
        Log.debug("InAppMessage Present Request: \(request)")

        let context = InAppMessagePresentationContext.of(request: request)
        let presented = await presenter.present(context: context)
        let response = InAppMessagePresentResponse.of(request: request, context: context)

        // 실제로 노출된 경우에만 impression을 기록한다. 노출되지 않은 메시지가 frequency cap을 소모하면 안 된다.
        if presented {
            recorder.record(request: request, response: response)
        }

        Log.debug("InAppMessage Present Response: \(response)")
        return response
    }
}
