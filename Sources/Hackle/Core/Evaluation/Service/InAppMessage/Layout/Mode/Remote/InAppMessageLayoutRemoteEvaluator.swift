import Foundation

final class InAppMessageLayoutRemoteEvaluator: RemoteEvaluator, InAppMessageLayoutEvaluator {

    typealias Request = InAppMessageLayoutRemoteEvaluateRequest
    typealias Response = InAppMessageLayoutEvaluateResponse

    let eventRecorder: EvaluationEventRecorder

    init(eventRecorder: EvaluationEventRecorder) {
        self.eventRecorder = eventRecorder
    }

    func remoteEvaluate(request: InAppMessageLayoutRemoteEvaluateRequest, context: EvaluatorContext) throws -> InAppMessageLayoutEvaluateResponse {
        InAppMessageLayoutEvaluateResponse.of(request: request, context: context, result: request.result)
    }
}
