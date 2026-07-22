import Foundation

protocol ExperimentConfig: Experiment, ConfigEntity {
    var name: String? { get }
    var identifierType: String { get }
    var variations: [Variation] { get }
    var userOverrides: [User.Id: Variation.Id] { get }
    var segmentOverrides: [TargetRule] { get }
    var targetAudiences: [Target] { get }
    var targetRules: [TargetRule] { get }
    var defaultRule: Action { get }
    var containerId: Container.Id? { get }
    var winnerVariation: Variation? { get }

    func getVariationOrNil(variationId: Variation.Id) -> Variation?
    func getVariationOrNil(variationKey: Variation.Key) -> Variation?
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
