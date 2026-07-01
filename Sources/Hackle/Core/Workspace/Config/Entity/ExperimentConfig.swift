import Foundation

protocol ExperimentConfig: Experiment, ConfigEntity {
}

extension ExperimentEntity: ExperimentConfig {
}
