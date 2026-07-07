import Foundation

protocol ExperimentConfig: Experiment, ConfigEntity {
}

extension ExperimentConfig {
    var controlVariation: Variation {
        get throws {
            guard let variation = getVariationOrNil(variationKey: "A") else {
                throw HackleError.error("ControlVariation[\(id)]")
            }
            return variation
        }
    }
}

extension ExperimentEntity: ExperimentConfig {
}
