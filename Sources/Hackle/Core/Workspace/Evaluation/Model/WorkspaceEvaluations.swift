import Foundation

extension ExperimentEvaluateResultDto {
    func toResult(type: ExperimentType) -> ExperimentRemoteEvaluateResult {
        return ExperimentRemoteEvaluateResult(
            id: id,
            key: key,
            version: version,
            order: order,
            type: type,
            executionVersion: executionVersion,
            variation: variation.toVariation(parameterConfiguration: config?.toParameterConfiguration()),
            reason: reason,
            references: references.compactMap { it in
                it.toEntityOrNil()
            }
        )
    }
}

extension RemoteConfigParameterEvaluateResultDto {
    func toResultOrNil() -> RemoteConfigParameterRemoteEvaluateResult? {
        guard let type: HackleValueType = Enums.parseOrNil(rawValue: valueType) else {
            return nil
        }
        return RemoteConfigParameterRemoteEvaluateResult(
            id: id,
            key: key,
            type: type,
            value: value?.toValue(),
            reason: reason,
            references: references.compactMap { it in
                it.toEntityOrNil()
            }
        )
    }
}

extension InAppMessageEligibilityEvaluateResultDto {
    func toResultOrNil() -> InAppMessageEligibilityRemoteEvaluateResult? {
        let period: InAppMessage.Period
        if let periodDto = self.period {
            guard let parsed = periodDto.toPeriodOrNil() else {
                return nil
            }
            period = parsed
        } else {
            period = .always
        }

        let timetable: InAppMessage.Timetable
        if let timetableDto = self.timetable {
            guard let parsed = timetableDto.toTimetableOrNil() else {
                return nil
            }
            timetable = parsed
        } else {
            timetable = .all
        }

        let delay: InAppMessage.EventTrigger.Delay
        if let delayDto = eventTriggerDelay {
            guard let parsed = delayDto.toDelayOrNil() else {
                return nil
            }
            delay = parsed
        } else {
            delay = InAppMessage.EventTrigger.Delay.default
        }

        let eventTrigger = InAppMessageEntity.EventTrigger(
            rules: eventTriggerRules.map { it in
                it.toTriggerRule()
            },
            frequencyCap: eventFrequencyCap?.toFrequencyCap(),
            delay: delay
        )

        let evaluateContext = self.evaluateContext.toEvaluateContext()

        guard let messageContext = messageContext.toMessageContextOrNil() else {
            return nil
        }

        guard let message = layout.message.toMessageOrNil() else {
            return nil
        }

        let layoutResult = InAppMessageLayoutRemoteEvaluateResult(
            id: id,
            key: key,
            order: order,
            period: period,
            timetable: timetable,
            eventTrigger: eventTrigger,
            evaluateContext: evaluateContext,
            messageContext: messageContext,
            message: message,
            reason: reason,
            references: layout.references.compactMap { it in
                it.toEntityOrNil()
            }
        )

        return InAppMessageEligibilityRemoteEvaluateResult(
            id: id,
            key: key,
            order: order,
            period: period,
            timetable: timetable,
            eventTrigger: eventTrigger,
            evaluateContext: evaluateContext,
            messageContext: messageContext,
            isEligible: isEligible,
            reason: reason,
            references: references.compactMap { it in
                it.toEntityOrNil()
            },
            layout: layoutResult
        )
    }
}

extension EntityDto {
    func toEntityOrNil() -> Entity? {
        guard let serviceType: ServiceType = Enums.parseOrNil(rawValue: type) else {
            return nil
        }
        return DefaultEntity(serviceType: serviceType, id: id)
    }
}

extension InAppMessageDto.PeriodDto {
    func toPeriodOrNil() -> InAppMessage.Period? {
        switch type {
        case "IMMEDIATE":
            return .always
        case "CUSTOM":
            guard let start = startMillisInclusive, let end = endMillisExclusive else {
                return nil
            }
            return .range(
                startInclusive: Date(timeIntervalSince1970: TimeInterval(start / 1000)),
                endExclusive: Date(timeIntervalSince1970: TimeInterval(end / 1000))
            )
        default:
            return nil
        }
    }
}
