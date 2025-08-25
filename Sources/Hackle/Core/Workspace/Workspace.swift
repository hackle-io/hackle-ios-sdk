//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Workspace {
    var id: Int64 { get }

    var environmentId: Int64 { get }

    var experiments: [Experiment] { get }

    var featureFlags: [Experiment] { get }

    var inAppMessages: [InAppMessage] { get }

    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment?

    func getFeatureFlagOrNil(featureKey: Experiment.Key) -> Experiment?

    func getBucketOrNil(bucketId: Bucket.Id) -> Bucket?

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType?

    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment?

    func getContainerOrNil(containerId: Container.Id) -> Container?

    func getParameterConfigurationOrNil(parameterConfigurationId: ParameterConfiguration.Id) -> ParameterConfiguration?

    func getRemoteConfigParameterOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameter?

    func getInAppMessageOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessage?
}

class WorkspaceEntity: Workspace {
    let id: Int64
    let environmentId: Int64
    let experiments: [Experiment]
    let featureFlags: [Experiment]
    let inAppMessages: [InAppMessage]
    private let buckets: [Bucket.Id: Bucket]
    private let eventTypes: [EventType.Key: EventType]
    private let segments: [Segment.Key: Segment]
    private let containers: [Container.Id: Container]
    private let parameterConfigurations: [ParameterConfiguration.Id: ParameterConfiguration]
    private let remoteConfigParameters: [RemoteConfigParameter.Key: RemoteConfigParameter]

    private let _experiments: [Experiment.Key: Experiment]
    private let _featureFlags: [Experiment.Key: Experiment]
    private let _inAppMessages: [InAppMessage.Key: InAppMessage]

    init(
        id: Int64,
        environmentId: Int64,
        experiments: [Experiment],
        featureFlags: [Experiment],
        buckets: [Bucket],
        eventTypes: [EventType],
        segments: [Segment],
        containers: [Container],
        parameterConfigurations: [ParameterConfiguration],
        remoteConfigParameters: [RemoteConfigParameter],
        inAppMessages: [InAppMessage]
    ) {
        self.id = id
        self.environmentId = environmentId
        self.experiments = experiments
        self.featureFlags = featureFlags
        self.inAppMessages = inAppMessages
        self.buckets = buckets.associateBy {
            $0.id
        }
        self.eventTypes = eventTypes.associateBy {
            $0.key
        }
        self.segments = segments.associateBy {
            $0.key
        }
        self.containers = containers.associateBy {
            $0.id
        }
        self.parameterConfigurations = parameterConfigurations.associateBy {
            $0.id
        }
        self.remoteConfigParameters = remoteConfigParameters.associateBy {
            $0.key
        }

        _experiments = experiments.associateBy {
            $0.key
        }
        _featureFlags = featureFlags.associateBy {
            $0.key
        }
        _inAppMessages = inAppMessages.associateBy {
            $0.key
        }
    }

    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment? {
        _experiments[experimentKey]
    }

    func getFeatureFlagOrNil(featureKey: Experiment.Key) -> Experiment? {
        _featureFlags[featureKey]
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

    func getContainerOrNil(containerId: Container.Id) -> Container? {
        containers[containerId]
    }

    func getParameterConfigurationOrNil(parameterConfigurationId: ParameterConfiguration.Id) -> ParameterConfiguration? {
        parameterConfigurations[parameterConfigurationId]
    }

    func getRemoteConfigParameterOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameter? {
        remoteConfigParameters[parameterKey]
    }

    func getInAppMessageOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessage? {
        _inAppMessages[inAppMessageKey]
    }

    static func from(dto: WorkspaceConfigDto) -> Workspace {
        let workspaceId = dto.workspace.id
        let environmentId = dto.workspace.environment.id

        let experiments = dto.experiments.compactMap { it in
            it.toExperimentOrNil(type: .abTest)
        }

        let featureFlags = dto.featureFlags.compactMap { it in
            it.toExperimentOrNil(type: .featureFlag)
        }

        let buckets = dto.buckets.map { it in
            it.toBucket()
        }

        let eventTypes = dto.events.map { it in
            it.toEventType()
        }

        let segments = dto.segments.compactMap { it in
            it.toSegmentOrNil()
        }

        let containers = dto.containers.map { it in
            it.toContainer()
        }

        let parameterConfigurations = dto.parameterConfigurations.map { it in
            it.toParameterConfiguration()
        }

        let remoteConfigParameters = dto.remoteConfigParameters.compactMap { it in
            it.toRemoteConfigParameterOrNil()
        }

        let inAppMessages = dto.inAppMessages.compactMap { it in
            it.toInAppMessageOrNil()
        }

        return WorkspaceEntity(
            id: workspaceId,
            environmentId: environmentId,
            experiments: experiments,
            featureFlags: featureFlags,
            buckets: buckets,
            eventTypes: eventTypes,
            segments: segments,
            containers: containers,
            parameterConfigurations: parameterConfigurations,
            remoteConfigParameters: remoteConfigParameters,
            inAppMessages: inAppMessages
        )
    }
}

struct WorkspaceConfig: Codable {
    var lastModified: String?
    var config: WorkspaceConfigDto
}

class WorkspaceConfigDto: Codable {
    var workspace: WorkspaceDto
    var experiments: [ExperimentDto]
    var featureFlags: [ExperimentDto]
    var buckets: [BucketDto]
    var events: [EventTypeDto]
    var segments: [SegmentDto]
    var containers: [ContainerDto]
    var parameterConfigurations: [ParameterConfigurationDto]
    var remoteConfigParameters: [RemoteConfigParameterDto]
    var inAppMessages: [InAppMessageDto]
}

class WorkspaceDto: Codable {
    var id: Int64
    var environment: EnvironmentDto
}

class EnvironmentDto: Codable {
    var id: Int64
}

class ExperimentDto: Codable {
    var id: Int64
    var key: Int64
    var name: String?
    var identifierType: String
    var status: String
    var version: Int
    var bucketId: Int64
    var variations: [VariationDto]
    var execution: ExecutionDto
    var winnerVariationId: Int64?
    var containerId: Int64?
}

class VariationDto: Codable {
    var id: Int64
    var key: String
    var status: String
    var parameterConfigurationId: Int64?
}

class ExecutionDto: Codable {
    var status: String
    var version: Int
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
        var values: [HackleValue]

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
            values = try container.decode([HackleValue].self, forKey: .values)
        }
    }

    class NumberOfEventsInDaysDto: Codable {
        /// 이벤트 키
        var eventKey: String
        /// 기간
        var days: Int
    }

    class NumberOfEventsWithPropertyInDaysDto: Codable {
        /// 이벤트 키
        var eventKey: String
        /// 기간
        var days: Int
        /// 프로퍼티 필터
        var propertyFilter: ConditionDto
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

class ContainerDto: Codable {
    var id: Int64
    var bucketId: Int64
    var groups: [ContainerGroupDto]
}

class ContainerGroupDto: Codable {
    var id: Int64
    var experiments: [Int64]
}

class ParameterConfigurationDto: Codable {
    var id: Int64
    var parameters: [ParameterDto]
}

class ParameterDto: Codable {
    var key: String
    var value: HackleValue
}

class RemoteConfigParameterDto: Codable {
    var id: Int64
    var key: String
    var type: String
    var identifierType: String
    var targetRules: [TargetRuleDto]
    var defaultValue: ValueDto

    class TargetRuleDto: Codable {
        var key: String
        var name: String
        var target: TargetDto
        var bucketId: Int64
        var value: ValueDto
    }

    class ValueDto: Codable {
        var id: Int64
        var value: HackleValue
    }
}

class DurationDto: Codable {
    var timeUnit: String
    var amount: Int64
}

class InAppMessageDto: Codable {
    var id: Int64
    var key: Int64
    var timeUnit: String
    var startEpochTimeMillis: Int64?
    var endEpochTimeMillis: Int64?
    var status: String
    var eventTriggerRules: [EventTriggerRuleDto]
    var eventFrequencyCap: EventFrequencyCapDto?
    var eventTriggerDelay: EventTriggerDelayDto?
    var evaluateContext: EvaluateContextDto?
    var targetContext: TargetContextDto
    var messageContext: MessageContextDto

    class EventTriggerRuleDto: Codable {
        var eventKey: String
        var targets: [TargetDto]
    }

    class EventFrequencyCapDto: Codable {
        var identifiers: [IdentifierCapDto]
        var duration: DurationCapDto?
    }

    class IdentifierCapDto: Codable {
        var identifierType: String
        var countPerIdentifier: Int64
    }

    class DurationCapDto: Codable {
        var durationUnit: DurationDto
        var countPerDuration: Int64
    }

    class EventTriggerDelayDto: Codable {
        var type: String
        var afterCondition: AfterConditionDto?

        class AfterConditionDto: Codable {
            var duration: DurationDto
        }
    }

    class EvaluateContextDto: Codable {
        var atDeliverTime: Bool
    }

    class TargetContextDto: Codable {
        var targets: [TargetDto]
        var overrides: [UserOverrideDto]

        class UserOverrideDto: Codable {
            var identifierType: String
            var identifiers: [String]
        }
    }

    class MessageContextDto: Codable {
        var defaultLang: String
        var exposure: ExposureDto
        var platformTypes: [String]
        var orientations: [String]
        var messages: [MessageDto]

        class ExposureDto: Codable {
            var type: String
            var key: Int64?
        }

        class MessageDto: Codable {
            var variationKey: String?
            var lang: String
            var layout: LayoutDto
            var images: [ImageDto]
            var imageAutoScroll: ImageAutoScrollDto?
            var text: TextDto?
            var buttons: [ButtonDto]
            var closeButton: CloseButtonDto?
            var background: BackgroundDto
            var action: ActionDto?
            var outerButtons: [PositionalButtonDto]
            var innerButtons: [PositionalButtonDto]

            class LayoutDto: Codable {
                var displayType: String
                var layoutType: String
                var alignment: AlignmentDto?
            }

            class ImageDto: Codable {
                var orientation: String
                var imagePath: String
                var action: ActionDto?
            }

            class ImageAutoScrollDto: Codable {
                var interval: DurationDto
            }

            class TextDto: Codable {
                var title: TextAttributeDto
                var body: TextAttributeDto

                class TextAttributeDto: Codable {
                    var text: String
                    var style: StyleDto
                }

                class StyleDto: Codable {
                    var textColor: String
                }
            }

            class ButtonDto: Codable {
                var text: String
                var style: StyleDto
                var action: ActionDto


                class StyleDto: Codable {
                    var textColor: String
                    var bgColor: String
                    var borderColor: String
                }
            }

            class CloseButtonDto: Codable {
                var style: StyleDto
                var action: ActionDto

                class StyleDto: Codable {
                    var color: String
                }
            }

            class BackgroundDto: Codable {
                var color: String
            }

            class ExposureDto: Codable {
                var type: String
                var key: Int64?
            }

            class AlignmentDto: Codable {
                var vertical: String
                var horizontal: String
            }

            class PositionalButtonDto: Codable {
                var button: ButtonDto
                var alignment: AlignmentDto
            }
        }

        class ActionDto: Codable {
            var behavior: String
            var type: String
            var value: String?
        }
    }
}

extension InAppMessageDto {
    func toInAppMessageOrNil() -> InAppMessage? {

        guard let status: InAppMessage.Status = Enums.parseOrNil(rawValue: status) else {
            return nil
        }

        let period: InAppMessage.Period
        switch timeUnit {
        case "IMMEDIATE":
            period = .always
            break
        case "CUSTOM":
            guard let start = startEpochTimeMillis, let end = endEpochTimeMillis else {
                return nil
            }
            period = .range(
                startInclusive: Date(timeIntervalSince1970: TimeInterval(start / 1000)),
                endExclusive: Date(timeIntervalSince1970: TimeInterval(end / 1000))
            )
            break
        default:
            return nil
        }

        guard let messageContext = messageContext.toMessageContextOrNil() else {
            return nil
        }

        let eventTriggerRules = eventTriggerRules.map({ $0.toTriggerRule() })
        let eventFrequencyCap = eventFrequencyCap?.toFrequencyCap()
        let eventTriggerDelay = eventTriggerDelay?.toDelayOrNil() ?? InAppMessage.EventTrigger.Delay.default

        return InAppMessage(
            id: id,
            key: key,
            status: status,
            period: period,
            eventTrigger: InAppMessage.EventTrigger(
                rules: eventTriggerRules,
                frequencyCap: eventFrequencyCap,
                delay: eventTriggerDelay
            ),
            evaluateContext: evaluateContext?.toEvaluateContext() ?? InAppMessage.EvaluateContext.default,
            targetContext: targetContext.toTargetContext(),
            messageContext: messageContext
        )
    }
}


extension InAppMessageDto.EventTriggerRuleDto {
    func toTriggerRule() -> InAppMessage.EventTrigger.Rule {
        InAppMessage.EventTrigger.Rule(eventKey: eventKey, targets: targets.compactMap {
            $0.toTargetOrNil(.property)
        })
    }
}

extension InAppMessageDto.EventFrequencyCapDto {
    func toFrequencyCap() -> InAppMessage.EventTrigger.FrequencyCap {
        InAppMessage.EventTrigger.FrequencyCap(
            identifierCaps: identifiers.map({ $0.toIdentifierCap() }),
            durationCap: duration?.toDurationCapOrNil()
        )
    }
}

extension InAppMessageDto.IdentifierCapDto {
    func toIdentifierCap() -> InAppMessage.EventTrigger.IdentifierCap {
        InAppMessage.EventTrigger.IdentifierCap(identifierType: identifierType, count: countPerIdentifier)
    }
}

extension InAppMessageDto.DurationCapDto {
    func toDurationCapOrNil() -> InAppMessage.EventTrigger.DurationCap? {
        guard let timeUnit: TimeUnit = Enums.parseOrNil(rawValue: durationUnit.timeUnit) else {
            return nil
        }
        return InAppMessage.EventTrigger.DurationCap(
            duration: timeUnit.convert(Double(durationUnit.amount), to: .seconds),
            count: countPerDuration
        )
    }
}

extension InAppMessageDto.TargetContextDto {
    func toTargetContext() -> InAppMessage.TargetContext {
        InAppMessage.TargetContext(
            overrides: overrides.map {
                $0.toUserOverride()
            },
            targets: targets.compactMap {
                $0.toTargetOrNil(.property)
            }
        )
    }
}

extension InAppMessageDto.EventTriggerDelayDto {
    func toDelayOrNil() -> InAppMessage.EventTrigger.Delay? {
        guard let type: InAppMessage.DelayType = Enums.parseOrNil(rawValue: type) else {
            return nil
        }
        let condition: InAppMessage.EventTrigger.Delay.AfterCondition?
        if afterCondition != nil {
            guard let model = afterCondition?.toAfterConditionOrNil() else {
                return nil
            }
            condition = model
        } else {
            condition = nil
        }
        return InAppMessage.EventTrigger.Delay(
            type: type,
            afterCondition: condition
        )
    }
}

extension InAppMessageDto.EventTriggerDelayDto.AfterConditionDto {
    func toAfterConditionOrNil() -> InAppMessage.EventTrigger.Delay.AfterCondition? {
        guard let timeUnit: TimeUnit = Enums.parseOrNil(rawValue: duration.timeUnit) else {
            return nil
        }
        return InAppMessage.EventTrigger.Delay.AfterCondition(
            duration: timeUnit.convert(Double(duration.amount), to: .seconds)
        )
    }
}

extension InAppMessageDto.EvaluateContextDto {
    func toEvaluateContext() -> InAppMessage.EvaluateContext {
        return InAppMessage.EvaluateContext(
            atDeliverTime: atDeliverTime
        )
    }
}

extension InAppMessageDto.TargetContextDto.UserOverrideDto {
    func toUserOverride() -> InAppMessage.UserOverride {
        InAppMessage.UserOverride(identifierType: identifierType, identifiers: identifiers)
    }
}

extension InAppMessageDto.MessageContextDto {

    func toMessageContextOrNil() -> InAppMessage.MessageContext? {

        var experimentContext: InAppMessage.ExperimentContext? = nil
        if exposure.type == "AB_TEST", let experimentKey = exposure.key {
            experimentContext = InAppMessage.ExperimentContext(key: experimentKey)
        }

        guard let platformTypes: [InAppMessage.PlatformType] = Enums.parseAllOrNil(platformTypes) else {
            return nil
        }

        guard let orientations: [InAppMessage.Orientation] = Enums.parseAllOrNil(orientations) else {
            return nil
        }

        guard let messages = messages.mapOrNil({ $0.toMessageOrNil() }) else {
            return nil
        }

        return InAppMessage.MessageContext(
            defaultLang: defaultLang,
            experimentContext: experimentContext,
            platformTypes: platformTypes,
            orientations: orientations,
            messages: messages
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto {
    func toMessageOrNil() -> InAppMessage.Message? {

        guard let layout = layout.toLayoutOrNil() else {
            return nil
        }

        guard let images = images.mapOrNil({ $0.toImageOrNil() }) else {
            return nil
        }

        var autoScroll: InAppMessage.Message.ImageAutoScroll? = nil
        if imageAutoScroll != nil {
            guard let s = imageAutoScroll?.toImageAutoScrollOrNil() else {
                return nil
            }
            autoScroll = s
        }

        guard let buttons = buttons.mapOrNil({ $0.toButtonOrNil() }) else {
            return nil
        }

        var xButton: InAppMessage.Message.Button? = nil
        if closeButton != nil {
            guard let b = closeButton?.toButtonOrNil() else {
                return nil
            }
            xButton = b
        }

        var messageAction: InAppMessage.Action? = nil
        if action != nil {
            guard let action = action?.toActionOrNil() else {
                return nil
            }
            messageAction = action
        }
        guard let outerButtons = outerButtons.mapOrNil({ $0.toPositionalButtonOrNil() }) else {
            return nil
        }
        guard let innerButtons = innerButtons.mapOrNil({ $0.toPositionalButtonOrNil() }) else {
            return nil
        }

        return InAppMessage.Message(
            variationKey: variationKey,
            lang: lang,
            layout: layout,
            images: images,
            imageAutoScroll: autoScroll,
            text: text?.toText(),
            buttons: buttons,
            closeButton: xButton,
            background: InAppMessage.Message.Background(color: background.color),
            action: messageAction,
            outerButtons: outerButtons,
            innerButtons: innerButtons
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.LayoutDto {
    func toLayoutOrNil() -> InAppMessage.Message.Layout? {
        guard let displayType: InAppMessage.DisplayType = Enums.parseOrNil(rawValue: displayType) else {
            return nil
        }
        guard let layoutType: InAppMessage.LayoutType = Enums.parseOrNil(rawValue: layoutType) else {
            return nil
        }

        var messageAlignment: InAppMessage.Message.Alignment? = nil
        if alignment != nil {
            guard let alignment = alignment?.toAlignmentOrNil() else {
                return nil
            }
            messageAlignment = alignment
        }

        return InAppMessage.Message.Layout(
            displayType: displayType,
            layoutType: layoutType,
            alignment: messageAlignment
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.ImageDto {
    func toImageOrNil() -> InAppMessage.Message.Image? {
        guard let orientation: InAppMessage.Orientation = Enums.parseOrNil(rawValue: orientation) else {
            return nil
        }

        var imageAction: InAppMessage.Action? = nil
        if action != nil {
            guard let action = action?.toActionOrNil() else {
                return nil
            }
            imageAction = action
        }

        return InAppMessage.Message.Image(
            orientation: orientation,
            imagePath: imagePath,
            action: imageAction
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.ImageAutoScrollDto {
    func toImageAutoScrollOrNil() -> InAppMessage.Message.ImageAutoScroll? {
        guard let timeUnit: TimeUnit = Enums.parseOrNil(rawValue: interval.timeUnit) else {
            return nil
        }
        return InAppMessage.Message.ImageAutoScroll(
            interval: timeUnit.convert(Double(interval.amount), to: .seconds)
        )
    }
}

extension InAppMessageDto.MessageContextDto.ActionDto {
    func toActionOrNil() -> InAppMessage.Action? {
        guard let behavior: InAppMessage.Behavior = Enums.parseOrNil(rawValue: behavior) else {
            return nil
        }
        guard let type: InAppMessage.ActionType = Enums.parseOrNil(rawValue: type) else {
            return nil
        }
        return InAppMessage.Action(behavior: behavior, type: type, value: value)
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.TextDto {
    func toText() -> InAppMessage.Message.Text {
        InAppMessage.Message.Text(
            title: title.toAttribute(),
            body: body.toAttribute()
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.TextDto.TextAttributeDto {
    func toAttribute() -> InAppMessage.Message.Text.Attribute {
        InAppMessage.Message.Text.Attribute(text: text, style: InAppMessage.Message.Text.Style(textColor: style.textColor))
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.ButtonDto {
    func toButtonOrNil() -> InAppMessage.Message.Button? {
        guard let action = action.toActionOrNil() else {
            return nil
        }
        return InAppMessage.Message.Button(
            text: text,
            style: InAppMessage.Message.Button.Style(
                textColor: style.textColor,
                bgColor: style.bgColor,
                borderColor: style.borderColor
            ),
            action: action
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.AlignmentDto {
    func toAlignmentOrNil() -> InAppMessage.Message.Alignment? {
        guard let vertical: InAppMessage.VerticalAlignment = Enums.parseOrNil(rawValue: vertical) else {
            return nil
        }
        guard let horizontal: InAppMessage.HorizontalAlignment = Enums.parseOrNil(rawValue: horizontal) else {
            return nil
        }
        return InAppMessage.Message.Alignment(
            vertical: vertical,
            horizontal: horizontal
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.PositionalButtonDto {
    func toPositionalButtonOrNil() -> InAppMessage.Message.PositionalButton? {
        guard let button = button.toButtonOrNil() else {
            return nil
        }
        guard let alignment = alignment.toAlignmentOrNil() else {
            return nil
        }
        return InAppMessage.Message.PositionalButton(
            button: button,
            alignment: alignment
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.CloseButtonDto {
    func toButtonOrNil() -> InAppMessage.Message.Button? {
        guard let action = action.toActionOrNil() else {
            return nil
        }

        return InAppMessage.Message.Button(
            text: "✕",
            style: InAppMessage.Message.Button.Style(
                textColor: style.color,
                bgColor: "#FFFFFF",
                borderColor: "#FFFFFF"
            ),
            action: action
        )
    }
}

extension SlotDto {
    func toSlot() -> Slot {
        SlotEntity(startInclusive: startInclusive, endExclusive: endExclusive, variationId: variationId)
    }
}

extension BucketDto {
    func toBucket() -> Bucket {
        BucketEntity(id: id, seed: seed, slotSize: slotSize, slots: slots.map {
            $0.toSlot()
        })
    }
}

extension VariationDto {
    func toVariation() -> Variation {
        VariationEntity(id: id, key: key, isDropped: status == "DROPPED", parameterConfigurationId: parameterConfigurationId)
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
            name: name,
            type: type,
            identifierType: identifierType,
            status: experimentStatus,
            version: version,
            executionVersion: execution.version,
            variations: variation,
            userOverrides: userOverrides,
            segmentOverrides: segmentOverrides,
            targetAudiences: targetAudiences,
            targetRules: targetRules,
            defaultRule: defaultRule,
            containerId: containerId,
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
            Log.debug("Unsupported experiment status [\(executionStatus)]")
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

        guard let valueType: HackleValueType = Enums.parseOrNil(rawValue: valueType) else {
            return nil
        }

        return Target.Match(type: matchType, matchOperator: matchOperator, valueType: valueType, values: values)
    }
}

extension TargetDto.NumberOfEventsInDaysDto {
    func toNumberOfEventInDay() -> Target.NumberOfEventsInDays {
        return Target.NumberOfEventsInDays(eventKey: eventKey, days: days)
    }
}

extension TargetDto.NumberOfEventsWithPropertyInDaysDto {
    func toNumberOfEventWithPropertyInDay() throws -> Target.NumberOfEventsWithPropertyInDays {
        guard let propertyFilter = propertyFilter.toConditionOrNil(.property) else {
            throw HackleError.error("propertyFilter is nil")
        }
        return Target.NumberOfEventsWithPropertyInDays(eventKey: eventKey, days: days, propertyFilter: propertyFilter)
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

extension ContainerDto {
    func toContainer() -> Container {
        ContainerEntity(
            id: id,
            bucketId: bucketId,
            groups: groups.map { it in
                it.toContainerGroup()
            }
        )
    }
}

extension ContainerGroupDto {
    func toContainerGroup() -> ContainerGroup {
        ContainerGroupEntity(
            id: id,
            experiments: experiments
        )
    }
}

extension ParameterConfigurationDto {
    func toParameterConfiguration() -> ParameterConfiguration {
        ParameterConfigurationEntity(
            id: id,
            parameters: parameters.associate { it in
                (it.key, it.value)
            }
        )
    }
}

extension RemoteConfigParameterDto {
    func toRemoteConfigParameterOrNil() -> RemoteConfigParameter? {
        guard let type: HackleValueType = Enums.parseOrNil(rawValue: type) else {
            return nil
        }
        return RemoteConfigParameter(
            id: id,
            key: key,
            type: type,
            identifierType: identifierType,
            targetRules: targetRules.compactMap { it in
                it.toTargetRuleOrNil()
            },
            defaultValue: defaultValue.toValue()
        )
    }
}

extension RemoteConfigParameterDto.TargetRuleDto {
    func toTargetRuleOrNil() -> RemoteConfigParameter.TargetRule? {
        guard let target = target.toTargetOrNil(.property) else {
            return nil
        }
        return RemoteConfigParameter.TargetRule(
            key: key,
            name: name,
            target: target,
            bucketId: bucketId,
            value: value.toValue()
        )
    }
}

extension RemoteConfigParameterDto.ValueDto {
    func toValue() -> RemoteConfigParameter.Value {
        RemoteConfigParameter.Value(id: id, rawValue: value)
    }
}

