import Foundation

protocol RemoteEvaluateResult: EvaluateResult, Entity {
    var references: [Entity] { get }

    func toEvaluation() -> Evaluation
}
