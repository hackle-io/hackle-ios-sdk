import Foundation

protocol RemoteEvaluateResult: EvaluateResult, Entity {
    associatedtype EvaluationType: Evaluation

    var references: [Entity] { get }

    func toEvaluation() -> EvaluationType
}
