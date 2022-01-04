//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Experiment {
    typealias Id = Int64
    typealias Key = Int64

    var id: Id { get }
    var key: Key { get }
    var type: ExperimentType { get }
    var status: ExperimentStatus { get }
    var targetAudiences: [Target] { get }
    var targetRules: [TargetRule] { get }
    var defaultRule: Action { get }
    var winnerVariation: Variation? { get }

    func getVariationOrNil(variationId: Variation.Id) -> Variation?
    func getVariationOrNil(variationKey: Variation.Key) -> Variation?
    func getOverriddenVariationOrNil(user: HackleUser) -> Variation?
}


enum ExperimentType: String, Codable {
    case abTest = "AB_TEST"
    case featureFlag = "FEATURE_FLAG"
}

enum ExperimentStatus {
    case draft
    case running
    case paused
    case completed
}


class ExperimentEntity: Experiment {
    let id: Id
    let key: Key
    let type: ExperimentType
    let status: ExperimentStatus
    private let variations: [Variation]
    private let overrides: [User.Id: Variation.Id]
    let targetAudiences: [Target]
    let targetRules: [TargetRule]
    let defaultRule: Action
    private let winnerVariationId: Variation.Id?

    init(id: Id, key: Key, type: ExperimentType, status: ExperimentStatus, variations: [Variation], overrides: [User.Id: Variation.Id], targetAudiences: [Target], targetRules: [TargetRule], defaultRule: Action, winnerVariationId: Variation.Id?) {
        self.id = id
        self.key = key
        self.type = type
        self.status = status
        self.variations = variations
        self.overrides = overrides
        self.targetAudiences = targetAudiences
        self.targetRules = targetRules
        self.defaultRule = defaultRule
        self.winnerVariationId = winnerVariationId
    }

    var winnerVariation: Variation? {
        get {
            variations.first { it in
                it.id == winnerVariationId
            }
        }
    }

    func getVariationOrNil(variationId: Variation.Id) -> Variation? {
        variations.first { it in
            it.id == variationId
        }
    }

    func getVariationOrNil(variationKey: Variation.Key) -> Variation? {
        variations.first { it in
            it.key == variationKey
        }
    }

    func getOverriddenVariationOrNil(user: HackleUser) -> Variation? {
        guard let overriddenVariationId = overrides[user.id] else {
            return nil
        }
        return getVariationOrNil(variationId: overriddenVariationId)
    }
}

