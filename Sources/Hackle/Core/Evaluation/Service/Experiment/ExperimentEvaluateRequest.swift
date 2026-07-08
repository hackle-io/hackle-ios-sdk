import Foundation

protocol ExperimentEvaluateRequest: EvaluateRequest {
    var experiment: Experiment { get }
}
