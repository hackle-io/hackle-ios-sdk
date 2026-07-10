import Foundation

protocol RemoteEvaluator: ContextualEvaluator where Request: RemoteEvaluateRequest {
    func remoteEvaluate(request: Request, context: EvaluatorContext) throws -> Response
}

extension RemoteEvaluator {

    func doEvaluate(request: Request, context: EvaluatorContext) throws -> Response {
        resolveReferences(request: request, context: context)
        return try remoteEvaluate(request: request, context: context)
    }

    private func resolveReferences(request: Request, context: EvaluatorContext) {
        for reference in request.remoteResult.references {
            if context.get(reference) != nil {
                continue
            }
            guard let result = request.evaluationWorkspace.result(entity: reference) else {
                continue
            }
            context.add(result.toEvaluation())
        }
    }
}
