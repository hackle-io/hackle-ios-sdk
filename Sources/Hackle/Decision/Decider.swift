//
// Created by yong on 2020/12/11.
//

import Foundation

enum Decision {
    case NotAllocated
    case ForcedAllocated(variationKey: Variation.Key)
    case NaturalAllocated(variation: Variation)
}

protocol Decider {
    func decide(experiment: Experiment, user: User) -> Decision
}

class BucketingDecider: Decider {

    private let bucketer : Bucketer

    init(bucketer: Bucketer = DefaultBucketer()) {
        self.bucketer = bucketer
    }

    func decide(experiment: Experiment, user: User) -> Decision {
        switch experiment {
        case let completed as Completed:
            return Decision.ForcedAllocated(variationKey: completed.winnerVariationKey)
        case let running as Running:
            return decide(runningExperiment: running, user: user)
        default:
            return Decision.NotAllocated
        }
    }

    private func decide(runningExperiment: Running, user: User) -> Decision {

        if let overriddenVariation = runningExperiment.getOverriddenVariationOrNil(user: user) {
            return Decision.ForcedAllocated(variationKey: overriddenVariation.key)
        }

        guard let allocatedSlot = bucketer.bucketing(bucket: runningExperiment.bucket, user: user) else {
            return Decision.NotAllocated
        }

        guard let allocatedVariation = runningExperiment.getVariationOrNil(variationId: allocatedSlot.variationId) else {
            return Decision.NotAllocated
        }

        if allocatedVariation.isDropped {
            return Decision.NotAllocated
        }

        return Decision.NaturalAllocated(variation: allocatedVariation)
    }
}
