import Foundation

protocol InAppMessageEvaluatorEvaluation: EvaluatorEvaluation {
    var reason: String { get }
    var targetEvaluations: [EvaluatorEvaluation] { get }
    var inAppMessage: InAppMessage { get }
}
