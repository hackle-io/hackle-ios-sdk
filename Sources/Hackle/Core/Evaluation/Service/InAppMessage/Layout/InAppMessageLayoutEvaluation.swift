import Foundation

final class InAppMessageLayoutEvaluation: Evaluation {
    let inAppMessage: InAppMessage
    let layoutResult: InAppMessageLayoutEvaluateResult

    var entity: Entity { inAppMessage }
    var result: EvaluateResult { layoutResult }

    init(entity: InAppMessage, result: InAppMessageLayoutEvaluateResult) {
        self.inAppMessage = entity
        self.layoutResult = result
    }
}
