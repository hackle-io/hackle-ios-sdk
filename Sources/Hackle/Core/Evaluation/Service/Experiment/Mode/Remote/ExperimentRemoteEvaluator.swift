import Foundation

final class ExperimentRemoteEvaluator: RemoteEvaluator, ExperimentEvaluator {

    typealias Request = ExperimentRemoteEvaluateRequest
    typealias Response = ExperimentEvaluateResponse

    let eventRecorder: EvaluationEventRecorder

    init(eventRecorder: EvaluationEventRecorder) {
        self.eventRecorder = eventRecorder
    }

    func remoteEvaluate(request: ExperimentRemoteEvaluateRequest, context: EvaluatorContext) throws -> ExperimentEvaluateResponse {
        ExperimentEvaluateResponse.of(request: request, context: context, result: request.result)
    }
}
