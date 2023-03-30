//
//  HackleAbTestItem.swift
//  Hackle
//
//  Created by yong on 2023/03/29.
//

import Foundation

struct HackleAbTestItem: Comparable {

    let experiment: Experiment
    let decision: Decision
    let overriddenVariation: Variation?

    static func <(lhs: HackleAbTestItem, rhs: HackleAbTestItem) -> Bool {
        lhs.experiment.key < rhs.experiment.key
    }

    static func ==(lhs: HackleAbTestItem, rhs: HackleAbTestItem) -> Bool {
        lhs.experiment.key == rhs.experiment.key
    }

    static func of(decisions: [(Experiment, Decision)], overrides: [Int64: Int64]) -> [HackleAbTestItem] {
        decisions.map { experiment, decision in
                var overriddenVariation: Variation? = nil
                if let overriddenVariationId = overrides[experiment.id] {
                    overriddenVariation = experiment.getVariationOrNil(variationId: overriddenVariationId)
                }
                return HackleAbTestItem(experiment: experiment, decision: decision, overriddenVariation: overriddenVariation)
            }
            .sorted(by: >)
    }
}
