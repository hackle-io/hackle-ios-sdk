//
//  HackleFeatureFlagItem.swift
//  Hackle
//
//  Created by yong on 2023/03/29.
//

import Foundation


struct HackleFeatureFlagItem: Comparable {

    let experiment: Experiment
    let decision: FeatureFlagDecision
    let overriddenVariation: Variation?

    static func <(lhs: HackleFeatureFlagItem, rhs: HackleFeatureFlagItem) -> Bool {
        lhs.experiment.key < rhs.experiment.key
    }

    static func ==(lhs: HackleFeatureFlagItem, rhs: HackleFeatureFlagItem) -> Bool {
        lhs.experiment.key == rhs.experiment.key
    }

    static func of(decisions: [(Experiment, FeatureFlagDecision)], overrides: [Int64: Int64]) -> [HackleFeatureFlagItem] {
        decisions.map { experiment, decision in
                var overriddenVariation: Variation? = nil
                if let overriddenVariationId = overrides[experiment.id] {
                    overriddenVariation = experiment.getVariationOrNil(variationId: overriddenVariationId)
                }
                return HackleFeatureFlagItem(experiment: experiment, decision: decision, overriddenVariation: overriddenVariation)
            }
            .sorted(by: >)
    }
}
