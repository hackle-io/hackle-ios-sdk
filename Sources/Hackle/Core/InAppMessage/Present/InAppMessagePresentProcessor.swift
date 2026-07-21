import Foundation

protocol InAppMessagePresentProcessor {
    func process(request: InAppMessagePresentRequest) async -> InAppMessagePresentResponse
}

class DefaultInAppMessagePresentProcessor: InAppMessagePresentProcessor {

    private let coreQueue: DispatchQueue
    private let presenter: InAppMessagePresenter
    private let recorder: InAppMessageRecorder

    init(coreQueue: DispatchQueue, presenter: InAppMessagePresenter, recorder: InAppMessageRecorder) {
        self.coreQueue = coreQueue
        self.presenter = presenter
        self.recorder = recorder
    }

    func process(request: InAppMessagePresentRequest) async -> InAppMessagePresentResponse {
        Log.debug("InAppMessage Present Request: \(request)")

        let context = InAppMessagePresentationContext.of(request: request)
        let response = await presenter.present(context: context)
        await record(request: request, response: response)

        Log.debug("InAppMessage Present Response: \(response)")
        return response
    }

    // record는 coreQueue에서 수행하고 완료까지 대기한다.
    // deliver 응답이 반환되는 시점에 impression 기록이 끝나 있어야 한다.
    private func record(request: InAppMessagePresentRequest, response: InAppMessagePresentResponse) async {
        await withCheckedContinuation { continuation in
            record(request: request, response: response) {
                continuation.resume()
            }
        }
    }

    private func record(request: InAppMessagePresentRequest, response: InAppMessagePresentResponse, completion: @escaping () -> Void) {
        coreQueue.async {
            self.recorder.record(request: request, response: response)
            completion()
        }
    }
}
