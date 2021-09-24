import Foundation

struct Evaluation: Equatable {
    let variationId: Variation.Id?
    let variationKey: Variation.Key
    let reason: String

    init(variationId: Variation.Id?, variationKey: Variation.Key, reason: String) {
        self.variationId = variationId
        self.variationKey = variationKey
        self.reason = reason
    }

    static func of(variation: Variation, reason: String) -> Evaluation {
        Evaluation(variationId: variation.id, variationKey: variation.key, reason: reason)
    }

    static func of(experiment: Experiment, variationKey: Variation.Key, reason: String) -> Evaluation {
        guard let variation = experiment.getVariationOrNil(variationKey: variationKey) else {
            return Evaluation(variationId: nil, variationKey: variationKey, reason: reason)
        }
        return of(variation: variation, reason: reason)
    }
}
