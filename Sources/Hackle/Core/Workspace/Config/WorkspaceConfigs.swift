import Foundation

extension InAppMessageDto {
    func toInAppMessageOrNil() -> InAppMessage? {
        guard let status: InAppMessage.Status = Enums.parseOrNil(rawValue: status) else {
            return nil
        }

        let period: InAppMessage.Period
        switch timeUnit {
        case "IMMEDIATE":
            period = .always
        case "CUSTOM":
            guard let start = startEpochTimeMillis, let end = endEpochTimeMillis else {
                return nil
            }
            period = .range(
                startInclusive: Date(epochMillis: start),
                endExclusive: Date(epochMillis: end)
            )
        default:
            return nil
        }

        guard let messageContext = messageContext.toMessageContextOrNil() else {
            return nil
        }

        let timetable = self.timetable?.toTimetableOrNil() ?? .all
        let eventTriggerRules = eventTriggerRules.map { $0.toTriggerRule() }
        let eventFrequencyCap = eventFrequencyCap?.toFrequencyCap()
        let eventTriggerDelay: InAppMessage.EventTrigger.Delay
        if let delayDto = self.eventTriggerDelay {
            guard let parsed = delayDto.toDelayOrNil() else {
                return nil
            }
            eventTriggerDelay = parsed
        } else {
            eventTriggerDelay = InAppMessage.EventTrigger.Delay.default
        }

        return InAppMessageEntity(
            id: id,
            key: key,
            order: order ?? 0,
            status: status,
            period: period,
            timetable: timetable,
            eventTrigger: InAppMessageEntity.EventTrigger(
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

extension InAppMessageDto.TimetableDto {
    func toTimetableOrNil() -> InAppMessage.Timetable? {
        switch type {
        case "ALL":
            return .all
        case "CUSTOM":
            let slots: [InAppMessage.TimetableSlot] = self.slots.compactMap {
                $0.toTimetableSlotOrNil()
            }
            return slots.isEmpty ? nil : .custom(slots: slots)
        default:
            return nil
        }
    }
}

extension InAppMessageDto.TimetableSlotDto {
    func toTimetableSlotOrNil() -> InAppMessage.TimetableSlot? {
        guard let dayOfWeek: DayOfWeek = Enums.parseOrNil(rawValue: dayOfWeek) else {
            return nil
        }
        let timeUnit = TimeUnit.milliseconds
        return InAppMessageEntity.TimetableSlot(
            dayOfWeek: dayOfWeek,
            startSecondsInclusive: timeUnit.convert(Double(startMillisInclusive), to: .seconds),
            endSecondsExclusive: timeUnit.convert(Double(endMillisExclusive), to: .seconds)
        )
    }
}

extension InAppMessageDto.EventTriggerRuleDto {
    func toTriggerRule() -> InAppMessage.EventTrigger.Rule {
        InAppMessageEntity.EventTrigger.Rule(eventKey: eventKey, targets: targets.compactMap {
            $0.toTargetOrNil(.property)
        })
    }
}

extension InAppMessageDto.EventFrequencyCapDto {
    func toFrequencyCap() -> InAppMessage.EventTrigger.FrequencyCap {
        InAppMessageEntity.EventTrigger.FrequencyCap(
            identifierCaps: identifiers.map { $0.toIdentifierCap() },
            durationCap: duration?.toDurationCapOrNil()
        )
    }
}

extension InAppMessageDto.IdentifierCapDto {
    func toIdentifierCap() -> InAppMessage.EventTrigger.IdentifierCap {
        InAppMessageEntity.EventTrigger.IdentifierCap(identifierType: identifierType, count: countPerIdentifier)
    }
}

extension InAppMessageDto.DurationCapDto {
    func toDurationCapOrNil() -> InAppMessage.EventTrigger.DurationCap? {
        guard let timeUnit: TimeUnit = Enums.parseOrNil(rawValue: durationUnit.timeUnit) else {
            return nil
        }
        return InAppMessageEntity.EventTrigger.DurationCap(
            duration: timeUnit.convert(Double(durationUnit.amount), to: .seconds),
            count: countPerDuration
        )
    }
}

extension InAppMessageDto.TargetContextDto {
    func toTargetContext() -> InAppMessage.TargetContext {
        InAppMessageEntity.TargetContext(
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
        return InAppMessageEntity.EventTrigger.Delay(
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
        return InAppMessageEntity.EventTrigger.Delay.AfterCondition(
            duration: timeUnit.convert(Double(duration.amount), to: .seconds)
        )
    }
}

extension InAppMessageDto.EvaluateContextDto {
    func toEvaluateContext() -> InAppMessage.EvaluateContext {
        return InAppMessageEntity.EvaluateContext(
            atDeliverTime: atDeliverTime
        )
    }
}

extension InAppMessageDto.TargetContextDto.UserOverrideDto {
    func toUserOverride() -> InAppMessage.UserOverride {
        InAppMessageEntity.UserOverride(identifierType: identifierType, identifiers: identifiers)
    }
}

extension InAppMessageDto.MessageContextDto {
    func toMessageContextOrNil() -> InAppMessage.MessageContext? {
        var experimentContext: InAppMessage.ExperimentContext? = nil
        if exposure.type == "AB_TEST", let experimentKey = exposure.key {
            experimentContext = InAppMessageEntity.ExperimentContext(key: experimentKey)
        }

        guard let platformTypes: [PlatformType] = Enums.parseAllOrNil(platformTypes) else {
            return nil
        }

        guard let orientations: [InAppMessage.Orientation] = Enums.parseAllOrNil(orientations) else {
            return nil
        }

        guard let messages = messages.mapOrNil({ $0.toMessageOrNil() }) else {
            return nil
        }

        return InAppMessageEntity.MessageContext(
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

        var messageHtml: InAppMessage.Message.Html? = nil
        if html != nil {
            guard let html = html?.toHtmlOrNil() else {
                return nil
            }
            messageHtml = html
        }

        if layout.displayType == .html && messageHtml == nil {
            return nil
        }

        return InAppMessageEntity.Message(
            variationKey: variationKey,
            lang: lang,
            layout: layout,
            images: images,
            imageAutoScroll: autoScroll,
            text: text?.toText(),
            buttons: buttons,
            closeButton: xButton,
            background: InAppMessageEntity.Message.Background(color: background.color),
            action: messageAction,
            outerButtons: outerButtons,
            innerButtons: innerButtons,
            html: messageHtml
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

        return InAppMessageEntity.Message.Layout(
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

        return InAppMessageEntity.Message.Image(
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
        return InAppMessageEntity.Message.ImageAutoScroll(
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
        return InAppMessageEntity.Action(behavior: behavior, type: type, value: value)
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.TextDto {
    func toText() -> InAppMessage.Message.Text {
        InAppMessageEntity.Message.Text(
            title: title.toAttribute(),
            body: body.toAttribute()
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.TextDto.TextAttributeDto {
    func toAttribute() -> InAppMessage.Message.Text.Attribute {
        InAppMessageEntity.Message.Text.Attribute(text: text, style: InAppMessageEntity.Message.Text.Style(textColor: style.textColor))
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.ButtonDto {
    func toButtonOrNil() -> InAppMessage.Message.Button? {
        guard let action = action.toActionOrNil() else {
            return nil
        }
        return InAppMessageEntity.Message.Button(
            text: text,
            style: InAppMessageEntity.Message.Button.Style(
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
        return InAppMessageEntity.Message.Alignment(
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
        return InAppMessageEntity.Message.PositionalButton(
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

        return InAppMessageEntity.Message.Button(
            text: "✕",
            style: InAppMessageEntity.Message.Button.Style(
                textColor: style.color,
                bgColor: "#FFFFFF",
                borderColor: "#FFFFFF"
            ),
            action: action
        )
    }
}

extension InAppMessageDto.MessageContextDto.MessageDto.HtmlDto {
    func toHtmlOrNil() -> InAppMessage.Message.Html? {
        guard let resourceType: InAppMessage.HtmlResourceType = Enums.parseOrNil(rawValue: resourceType) else {
            return nil
        }
        switch resourceType {
        case .text:
            guard let text = text else {
                return nil
            }
            return InAppMessageEntity.Message.Html(resourceType: resourceType, text: text, path: nil)
        case .path:
            guard let path = path else {
                return nil
            }
            return InAppMessageEntity.Message.Html(resourceType: resourceType, text: nil, path: path)
        }
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
    func toVariation(parameterConfigurations: [ParameterConfiguration.Id: ParameterConfiguration]) -> Variation {
        toVariation(parameterConfiguration: parameterConfigurationId.flatMap { id in
            parameterConfigurations[id]
        })
    }

    func toVariation(parameterConfiguration: ParameterConfiguration?) -> Variation {
        VariationEntity(
            id: id,
            key: key,
            isDropped: status == "DROPPED",
            parameterConfiguration: parameterConfiguration
        )
    }
}

extension ExperimentDto {
    func toExperimentOrNil(type: ExperimentType, parameterConfigurations: [ParameterConfiguration.Id: ParameterConfiguration]) -> Experiment? {
        guard let experimentStatus = ExperimentStatus.from(executionStatus: execution.status) else {
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
            it.toVariation(parameterConfigurations: parameterConfigurations)
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
            order: order ?? 0,
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
        return RemoteConfigParameterEntity(
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
        return RemoteConfigParameterEntity.TargetRule(
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
        RemoteConfigParameterEntity.Value(id: id, rawValue: value)
    }
}
