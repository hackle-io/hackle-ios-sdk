//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Workspace {
    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment?

    func getFeatureFlagOrNil(featureKey: Experiment.Key) -> Experiment?

    func getBucketOrNil(bucketId: Bucket.Id) -> Bucket?

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType?

    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment?
}

class WorkspaceEntity: Workspace {

    private let experiments: [Experiment.Key: Experiment]
    private let featureFlags: [Experiment.Key: Experiment]
    private let buckets: [Bucket.Id: Bucket]
    private let eventTypes: [EventType.Key: EventType]
    private let segments: [Segment.Key: Segment]


    init(
        experiments: [Experiment.Key: Experiment],
        featureFlags: [Experiment.Key: Experiment],
        buckets: [Bucket.Id: Bucket],
        eventTypes: [EventType.Key: EventType],
        segments: [Segment.Key: Segment]
    ) {
        self.experiments = experiments
        self.featureFlags = featureFlags
        self.buckets = buckets
        self.eventTypes = eventTypes
        self.segments = segments
    }

    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment? {
        experiments[experimentKey]
    }

    func getFeatureFlagOrNil(featureKey: Experiment.Key) -> Experiment? {
        featureFlags[featureKey]
    }

    func getBucketOrNil(bucketId: Bucket.Id) -> Bucket? {
        buckets[bucketId]
    }

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType? {
        eventTypes[eventTypeKey]
    }

    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment? {
        segments[segmentKey]
    }

    static func from(dto: WorkspaceDto) -> Workspace {

        let buckets = dto.buckets.associate { it in
            (it.id, it.toBucket())
        }

        let experiments = dto.experiments
            .compactMap { it in
                it.toExperimentOrNil(type: .abTest)
            }
            .associateBy { it in
                it.key
            }

        let featureFlags = dto.featureFlags
            .compactMap { it in
                it.toExperimentOrNil(type: .featureFlag)
            }
            .associateBy { it in
                it.key
            }

        let eventTypes: [EventType.Key: EventType] = dto.events.associate { it in
            (it.key, it.toEventType())
        }

        let segments = dto.segments
            .compactMap { it in
                it.toSegmentOrNil()
            }
            .associateBy { it in
                it.key
            }

        return WorkspaceEntity(
            experiments: experiments,
            featureFlags: featureFlags,
            buckets: buckets,
            eventTypes: eventTypes,
            segments: segments
        )
    }
}

class WorkspaceDto: Codable {
    var experiments: [ExperimentDto]
    var featureFlags: [ExperimentDto]
    var buckets: [BucketDto]
    var events: [EventTypeDto]
    var segments: [SegmentDto]
}

class ExperimentDto: Codable {
    var id: Int64
    var key: Int64
    var status: String
    var bucketId: Int64
    var variations: [VariationDto]
    var execution: ExecutionDto
    var winnerVariationId: Int64?
}

class VariationDto: Codable {
    var id: Int64
    var key: String
    var status: String
}

class ExecutionDto: Codable {
    var status: String
    var userOverrides: [UserOverrideDto]
    var segmentOverrides: [TargetRuleDto]
    var targetAudiences: [TargetDto]
    var targetRules: [TargetRuleDto]
    var defaultRule: TargetActionDto
}

class UserOverrideDto: Codable {
    var userId: String
    var variationId: Int64
}

class BucketDto: Codable {
    var id: Int64
    var seed: Int32
    var slotSize: Int32
    var slots: [SlotDto]
}

class SlotDto: Codable {
    var startInclusive: Int
    var endExclusive: Int
    var variationId: Int64
}

class EventTypeDto: Codable {
    var id: Int64
    var key: String
}

class TargetDto: Codable {

    var conditions: [ConditionDto]

    class ConditionDto: Codable {
        var key: KeyDto
        var match: MatchDto
    }

    class KeyDto: Codable {
        var type: String
        var name: String
    }

    class MatchDto: Codable {
        var type: String
        var matchOperator: String
        var valueType: String
        var values: [MatchValue]

        enum CodingKeys: String, CodingKey {
            case type
            case matchOperator = "operator"
            case valueType
            case values
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)
            matchOperator = try container.decode(String.self, forKey: .matchOperator)
            valueType = try container.decode(String.self, forKey: .valueType)
            values = try container.decode([MatchValue].self, forKey: .values)
        }
    }
}


class TargetActionDto: Codable {
    var type: String
    var variationId: Int64?
    var bucketId: Int64?
}

class TargetRuleDto: Codable {
    var target: TargetDto
    var action: TargetActionDto
}

class SegmentDto: Codable {
    var id: Int64
    var key: String
    var type: String
    var targets: [TargetDto]
}

extension SlotDto {
    func toSlot() -> Slot {
        SlotEntity(startInclusive: startInclusive, endExclusive: endExclusive, variationId: variationId)
    }
}

extension BucketDto {
    func toBucket() -> Bucket {
        BucketEntity(seed: seed, slotSize: slotSize, slots: slots.map {
            $0.toSlot()
        })
    }
}

extension VariationDto {
    func toVariation() -> Variation {
        VariationEntity(id: id, key: key, isDropped: status == "DROPPED")
    }
}

extension ExperimentDto {
    func toExperimentOrNil(type: ExperimentType) -> Experiment? {

        guard let experimentStatus = ExperimentDto.experimentStatusOrNil(executionStatus: execution.status) else {
            return nil
        }

        guard let defaultRule = execution.defaultRule.toActionOrNil() else {
            return nil
        }

        let targetAudiences = execution.targetAudiences.compactMap { it in
            it.toTargetOrNil(.property)
        }
        let targetRules = execution.targetRules.compactMap { it in
            it.toTargetRuleOrNil(.property)
        }

        let variation = variations.map { it in
            it.toVariation()
        }

        let userOverrides = execution.userOverrides.associate { it in
            (it.userId, it.variationId)
        }

        let segmentOverrides = execution.segmentOverrides.compactMap { it in
            it.toTargetRuleOrNil(.identifier)
        }

        return ExperimentEntity(
            id: id,
            key: key,
            type: type,
            status: experimentStatus,
            variations: variation,
            userOverrides: userOverrides,
            segmentOverrides: segmentOverrides,
            targetAudiences: targetAudiences,
            targetRules: targetRules,
            defaultRule: defaultRule,
            winnerVariationId: winnerVariationId
        )
    }

    static func experimentStatusOrNil(executionStatus: String) -> ExperimentStatus? {
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
            Log.debug("Unsupported status [\(executionStatus)]")
            return nil
        }
    }
}

extension TargetDto {
    func toTargetOrNil(_ targetingType: TargetingType) -> Target? {
        let condition = conditions.compactMap { it in
            it.toConditionOrNil(targetingType)
        }
        if condition.isEmpty {
            return nil
        } else {
            return Target(conditions: condition)
        }
    }
}

extension TargetDto.ConditionDto {
    func toConditionOrNil(_ targetingType: TargetingType) -> Target.Condition? {
        guard let key = key.toTargetKeyOrNil(), targetingType.supports(keyType: key.type) else {
            return nil
        }

        guard let match = match.toMatchOrNil() else {
            return nil
        }

        return Target.Condition(key: key, match: match)
    }
}

extension TargetDto.KeyDto {
    func toTargetKeyOrNil() -> Target.Key? {
        guard let keyType: Target.KeyType = Enums.parseOrNil(rawValue: type) else {
            return nil
        }
        return Target.Key(type: keyType, name: name)
    }
}

extension TargetDto.MatchDto {
    func toMatchOrNil() -> Target.Match? {
        guard let matchType: Target.MatchType = Enums.parseOrNil(rawValue: type) else {
            return nil
        }

        guard let matchOperator: Target.Match.Operator = Enums.parseOrNil(rawValue: matchOperator) else {
            return nil
        }

        guard let valueType: Target.Match.ValueType = Enums.parseOrNil(rawValue: valueType) else {
            return nil
        }

        return Target.Match(type: matchType, matchOperator: matchOperator, valueType: valueType, values: values)
    }
}

extension TargetActionDto {
    func toActionOrNil() -> Action? {
        guard let actionType: ActionType = Enums.parseOrNil(rawValue: type) else {
            return nil
        }
        return ActionEntity(type: actionType, variationId: variationId, bucketId: bucketId)
    }
}

extension TargetRuleDto {
    func toTargetRuleOrNil(_ targetingType: TargetingType) -> TargetRule? {
        guard let target = target.toTargetOrNil(targetingType) else {
            return nil
        }
        guard let action = action.toActionOrNil() else {
            return nil
        }
        return TargetRuleEntity(target: target, action: action)
    }
}

extension EventTypeDto {
    func toEventType() -> EventType {
        EventTypeEntity(id: id, key: key)
    }
}

extension SegmentDto {
    func toSegmentOrNil() -> Segment? {
        guard let segmentType: SegmentType = Enums.parseOrNil(rawValue: type) else {
            return nil
        }
        return SegmentEntity(
            id: id,
            key: key,
            type: segmentType,
            targets: targets.compactMap { it in
                it.toTargetOrNil(.segment)
            }
        )
    }
}
