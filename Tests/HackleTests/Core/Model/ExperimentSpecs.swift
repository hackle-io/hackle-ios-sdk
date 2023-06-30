//
//  ExperimentSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
@testable import Hackle

func experiment(
    id: Experiment.Id = 1,
    key: Experiment.Key = 1,
    type: ExperimentType = .abTest,
    identifierType: String = "$id",
    status: ExperimentStatus = .running,
    containerId: Container.Id? = nil,
    version: Int = 1,
    winnerVariationId: Variation.Id? = nil,
    variations: [Variation] = [
        VariationEntity(id: 1, key: "A", isDropped: false, parameterConfigurationId: nil),
        VariationEntity(id: 2, key: "B", isDropped: false, parameterConfigurationId: nil)
    ],
    targetAudiences: [Target] = []
) -> Experiment {
    ExperimentEntity(
        id: id,
        key: key,
        type: type,
        identifierType: identifierType,
        status: status,
        version: version,
        variations: variations,
        userOverrides: [:],
        segmentOverrides: [],
        targetAudiences: targetAudiences,
        targetRules: [],
        defaultRule: ActionEntity(type: .bucket, variationId: 1, bucketId: 1),
        containerId: containerId,
        winnerVariationId: winnerVariationId
    )
}
