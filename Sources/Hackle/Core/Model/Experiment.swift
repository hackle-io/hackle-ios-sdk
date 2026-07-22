//

import Foundation

protocol Experiment: Entity, Sendable {
    typealias Id = Int64
    typealias Key = Int64

    var id: Id { get }
    var key: Key { get }
    var version: Int { get }
    var status: ExperimentStatus { get }
    var order: Int64 { get }
    var type: ExperimentType { get }
    var executionVersion: Int { get }
}

extension Experiment {
    var serviceType: ServiceType {
        switch type {
        case .abTest:
            return .abTest
        case .featureFlag:
            return .featureFlag
        }
    }
}


enum ExperimentType: String, Codable {
    case abTest = "AB_TEST"
    case featureFlag = "FEATURE_FLAG"
}

enum ExperimentStatus: String {
    case draft
    case running
    case paused
    case completed

    static func from(executionStatus: String) -> ExperimentStatus? {
        switch executionStatus {
        case "READY":
            return .draft
        case "RUNNING":
            return .running
        case "PAUSED":
            return .paused
        case "STOPPED":
            return .completed
        default:
            Log.debug("Unsupported experiment status [\(executionStatus)]")
            return nil
        }
    }
}

final class ExperimentEntity: Experiment, Sendable {
    let id: Id
    let key: Key
    let name: String?
    let type: ExperimentType
    let identifierType: String
    let status: ExperimentStatus
    let version: Int
    let order: Int64
    let executionVersion: Int
    let variations: [Variation]
    let userOverrides: [User.Id: Variation.Id]
    let segmentOverrides: [TargetRule]
    let targetAudiences: [Target]
    let targetRules: [TargetRule]
    let defaultRule: Action
    let containerId: Container.Id?
    private let winnerVariationId: Variation.Id?

    init(
        id: Id,
        key: Key,
        name: String?,
        type: ExperimentType,
        identifierType: String,
        status: ExperimentStatus,
        version: Int,
        order: Int64,
        executionVersion: Int,
        variations: [Variation],
        userOverrides: [User.Id: Variation.Id],
        segmentOverrides: [TargetRule],
        targetAudiences: [Target],
        targetRules: [TargetRule],
        defaultRule: Action,
        containerId: Container.Id?,
        winnerVariationId: Variation.Id?
    ) {
        self.id = id
        self.key = key
        self.name = name
        self.type = type
        self.identifierType = identifierType
        self.status = status
        self.version = version
        self.order = order
        self.executionVersion = executionVersion
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

