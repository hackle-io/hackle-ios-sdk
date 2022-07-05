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
    var identifierType: String { get }
    var status: ExperimentStatus { get }
    var version: Int { get }
    var userOverrides: [User.Id: Variation.Id] { get }
    var segmentOverrides: [TargetRule] { get }
    var targetAudiences: [Target] { get }
    var targetRules: [TargetRule] { get }
    var defaultRule: Action { get }
    var contianerId: Int64? {get}
    var winnerVariation: Variation? { get }

    func getVariationOrNil(variationId: Variation.Id) -> Variation?
    func getVariationOrNil(variationKey: Variation.Key) -> Variation?
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
    let identifierType: String
    let status: ExperimentStatus
    let version: Int
    private let variations: [Variation]
    let userOverrides: [User.Id: Variation.Id]
    let segmentOverrides: [TargetRule]
    let targetAudiences: [Target]
    let targetRules: [TargetRule]
    let defaultRule: Action
    let containerId: Int64?
    private let winnerVariationId: Variation.Id?

    init(id: Id, key: Key, type: ExperimentType, identifierType: String, status: ExperimentStatus, version: Int, variations: [Variation], userOverrides: [User.Id: Variation.Id], segmentOverrides: [TargetRule], targetAudiences: [Target], targetRules: [TargetRule], defaultRule: Action, containerId: Int64?, winnerVariationId: Variation.Id?) {
        self.id = id
        self.key = key
        self.type = type
        self.identifierType = identifierType
        self.status = status
        self.version = version
        self.variations = variations
        self.userOverrides = userOverrides
        self.segmentOverrides = segmentOverrides
        self.targetAudiences = targetAudiences
        self.targetRules = targetRules
        self.defaultRule = defaultRule
        self.containerId = containerId
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
}

