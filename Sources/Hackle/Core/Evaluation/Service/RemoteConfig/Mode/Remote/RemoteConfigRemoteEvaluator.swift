import Foundation

final class RemoteConfigRemoteEvaluator: RemoteEvaluator, RemoteConfigEvaluator {

    typealias Request = RemoteConfigRemoteEvaluateRequest
    typealias Response = RemoteConfigEvaluateResponse

    let eventRecorder: EvaluationEventRecorder

    init(eventRecorder: EvaluationEventRecorder) {
        self.eventRecorder = eventRecorder
    }

    func remoteEvaluate(request: RemoteConfigRemoteEvaluateRequest, context: EvaluatorContext) throws -> RemoteConfigEvaluateResponse {
        let result = RemoteConfigEvaluateResult.of(request: request, value: request.result.value, reason: request.result.reason)
        return RemoteConfigEvaluateResponse.of(request: request, context: context, result: result)
    }
}
