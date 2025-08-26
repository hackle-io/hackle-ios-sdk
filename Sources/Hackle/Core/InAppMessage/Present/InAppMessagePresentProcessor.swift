import Foundation

protocol InAppMessagePresentProcessor {
    func process(request: InAppMessagePresentRequest) throws -> InAppMessagePresentResponse
}

class DefaultInAppMessagePresentProcessor: InAppMessagePresentProcessor {

    private let contextResolver: InAppMessagePresentationContextResolver
    private let presenter: InAppMessagePresenter
    private let recorder: InAppMessageRecorder

    init(contextResolver: InAppMessagePresentationContextResolver, presenter: InAppMessagePresenter, recorder: InAppMessageRecorder) {
        self.contextResolver = contextResolver
        self.presenter = presenter
        self.recorder = recorder
    }

    func process(request: InAppMessagePresentRequest) throws -> InAppMessagePresentResponse {
        Log.debug("InAppMessage Present Request: \(request)")

        let response = try present(requset: request)
        recorder.record(request: request, response: response)

        Log.debug("InAppMessage Present Response: \(response)")
        return response
    }

    private func present(requset: InAppMessagePresentRequest) throws -> InAppMessagePresentResponse {
        let context = try contextResolver.resolve(requset: requset)
        presenter.present(context: context)
        return InAppMessagePresentResponse.of(request: requset, context: context)
    }
}
