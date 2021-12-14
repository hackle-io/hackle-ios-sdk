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

    func getVariationOrNil(variationId: Variation.Id) -> Variation?
    func getVariationOrNil(variationKey: Variation.Key) -> Variation?
    func getOverriddenVariationOrNil(user: HackleUser) -> Variation?

}

enum ExperimentType: String, Codable {
    case abTest = "AB_TEST"
    case featureFlag = "FEATURE_FLAG"
}

protocol DraftExperiment: Experiment {
}


protocol RunningExperiment: Experiment {
    var targetAudiences: [Target] { get }
    var targetRules: [TargetRule] { get }
    var defaultRule: Action { get }
}

protocol PausedExperiment: Experiment {
}

protocol CompletedExperiment: Experiment {
    var winnerVariation: Variation { get }
}

class BaseExperiment: Experiment {
    let id: Id
    let key: Key
    let type: ExperimentType
    let variations: [Variation]
    let overrides: [User.Id: Variation.Id]

    init(id: Id, key: Key, type: ExperimentType, variations: [Variation], overrides: [User.Id: Variation.Id]) {
        self.id = id
        self.key = key
        self.type = type
        self.variations = variations
        self.overrides = overrides
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


class DraftExperimentEntity: BaseExperiment, DraftExperiment {

}

class RunningExperimentEntity: BaseExperiment, RunningExperiment {

    let targetAudiences: [Target]
    let targetRules: [TargetRule]
    let defaultRule: Action

    init(id: Id, key: Key, type: ExperimentType, variations: [Variation], overrides: [User.Id: Variation.Id], targetAudiences: [Target], targetRules: [TargetRule], defaultRule: Action) {
        self.targetAudiences = targetAudiences
        self.targetRules = targetRules
        self.defaultRule = defaultRule
        super.init(id: id, key: key, type: type, variations: variations, overrides: overrides)
    }
}

class PausedExperimentEntity: BaseExperiment, PausedExperiment {

}

class CompletedExperimentEntity: BaseExperiment, CompletedExperiment {
    internal let winnerVariationId: Variation.Id
    var winnerVariation: Variation {
        get {
            getVariationOrNil(variationId: winnerVariationId)!
        }
    }

    init(id: Id, key: Key, type: ExperimentType, variations: [Variation], overrides: [User.Id: Variation.Id], winnerVariationId: Variation.Id) {
        self.winnerVariationId = winnerVariationId
        super.init(id: id, key: key, type: type, variations: variations, overrides: overrides)
    }

}
