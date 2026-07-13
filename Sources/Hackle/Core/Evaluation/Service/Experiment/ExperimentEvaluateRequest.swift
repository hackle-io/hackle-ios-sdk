import Foundation

protocol ExperimentEvaluateRequest: EvaluateRequest {
    var experiment: Experiment { get }
}

extension ExperimentEvaluateRequest {
    var entity: Entity { experiment }
}
