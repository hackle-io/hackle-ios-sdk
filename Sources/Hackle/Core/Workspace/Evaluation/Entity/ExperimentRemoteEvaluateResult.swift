import Foundation

final class ExperimentRemoteEvaluateResult: ExperimentEvaluateResult, Experiment, RemoteEvaluateResult, @unchecked Sendable {

    let id: Experiment.Id
    let key: Experiment.Key
    let version: Int
    let type: ExperimentType
    let executionVersion: Int
    let references: [Entity]

    init(
        id: Experiment.Id,
        key: Experiment.Key,
        version: Int,
        type: ExperimentType,
        executionVersion: Int,
        variation: Variation,
        reason: String,
        references: [Entity]
    ) {
        self.id = id
        self.key = key
        self.version = version
        self.type = type
        self.executionVersion = executionVersion
        self.references = references
        super.init(reason: reason, variation: variation)
    }

    func toEvaluation() -> Evaluation {
        ExperimentEvaluation(entity: self, result: self)
    }

    override var description: String {
        "ExperimentRemoteEvaluateResult(id=\(id), key=\(key), type=\(type), version=\(version), variation=\(variation), reason=\(reason))"
    }
}
