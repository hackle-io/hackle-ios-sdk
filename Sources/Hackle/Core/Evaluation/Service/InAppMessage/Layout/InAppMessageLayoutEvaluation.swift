import Foundation

final class InAppMessageLayoutEvaluation: Evaluation {
    let inAppMessage: InAppMessage
    let layoutResult: InAppMessageLayoutEvaluateResult
    let properties: [String: Any]

    var entity: Entity { inAppMessage }
    var result: EvaluateResult { layoutResult }

    init(entity: InAppMessage, result: InAppMessageLayoutEvaluateResult, properties: [String: Any] = [:]) {
        self.inAppMessage = entity
        self.layoutResult = result
        self.properties = properties
    }
}
