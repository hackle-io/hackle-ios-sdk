import Foundation

/// UserExplorer 디버그 전용. 평가 엔진을 수정하지 않고 read-only로 디테일을 재구성한다.
class InAppMessageDebugInspector {

    private let impressionStorage: InAppMessageImpressionStorage
    private let hiddenStorage: InAppMessageHiddenStorage
    private let valueOperatorMatcher: ValueOperatorMatcher
    private let userValueResolver: UserValueResolver

    init(
        impressionStorage: InAppMessageImpressionStorage,
        hiddenStorage: InAppMessageHiddenStorage,
        valueOperatorMatcher: ValueOperatorMatcher,
        userValueResolver: UserValueResolver
    ) {
        self.impressionStorage = impressionStorage
        self.hiddenStorage = hiddenStorage
        self.valueOperatorMatcher = valueOperatorMatcher
        self.userValueResolver = userValueResolver
    }

    // MARK: - Target

    func targetDetails(
        inAppMessage: InAppMessage,
        user: HackleUser,
        abTestDecisions: [Experiment.Key: Decision] = [:],
        featureFlagDecisions: [Experiment.Key: FeatureFlagDecision] = [:]
    ) -> [TargetGroupDetail] {
        inAppMessage.targetContext.targets.enumerated().map { index, target in
            TargetGroupDetail(
                index: index + 1,
                conditions: target.conditions.map {
                    conditionDetail(
                        condition: $0,
                        user: user,
                        abTestDecisions: abTestDecisions,
                        featureFlagDecisions: featureFlagDecisions
                    )
                }
            )
        }
    }

    private func conditionDetail(
        condition: Target.Condition,
        user: HackleUser,
        abTestDecisions: [Experiment.Key: Decision],
        featureFlagDecisions: [Experiment.Key: FeatureFlagDecision]
    ) -> ConditionDetail {
        let keyType = condition.key.type
        let requirement = requirementString(condition.match)

        switch keyType {
        case .userId, .userProperty, .hackleProperty:
            let resolved = try? userValueResolver.resolveOrNil(user: user, key: condition.key)
            let userValue: Any? = resolved ?? nil
            let isMatched = valueOperatorMatcher.matches(userValue: userValue, match: condition.match)
            return ConditionDetail(
                keyType: keyType.rawValue,
                keyName: condition.key.name,
                requirement: requirement,
                userValue: userValue.map { "\($0)" },
                isMatched: isMatched,
                matchType: condition.match.type,
                isUserProperty: true
            )
        case .abTest:
            return ConditionDetail(
                keyType: keyType.rawValue,
                keyName: condition.key.name,
                requirement: requirement,
                userValue: nil,
                isMatched: abTestMatched(condition: condition, decisions: abTestDecisions),
                matchType: condition.match.type,
                isUserProperty: false
            )
        case .featureFlag:
            return ConditionDetail(
                keyType: keyType.rawValue,
                keyName: condition.key.name,
                requirement: requirement,
                userValue: nil,
                isMatched: featureFlagMatched(condition: condition, decisions: featureFlagDecisions),
                matchType: condition.match.type,
                isUserProperty: false
            )
        case .eventProperty, .segment, .cohort, .numberOfEventsInDays, .numberOfEventsWithPropertyInDays:
            // 트리거 이벤트나 추가 평가 컨텍스트가 필요해 디버그 화면에서는 평가하지 않는다.
            return ConditionDetail(
                keyType: keyType.rawValue,
                keyName: condition.key.name,
                requirement: requirement,
                userValue: nil,
                isMatched: nil,
                matchType: condition.match.type,
                isUserProperty: false
            )
        }
    }

    /// 조건 표현식 문자열. NOT_MATCH 조건은 "NOT" 접두사를 붙인다.
    private func requirementString(_ match: Target.Match) -> String {
        let values = match.values.map { $0.asString() ?? "" }.joined(separator: ", ")
        return "\(match.matchOperator.rawValue) [\(values)]"
    }

    /// 이미 평가된 AB 테스트 결정을 재사용해 조건 매칭 여부를 재현한다. (`AbTestConditionMatcher`와 동일 규칙)
    private func abTestMatched(condition: Target.Condition, decisions: [Experiment.Key: Decision]) -> Bool? {
        guard let key = Experiment.Key(condition.key.name), let decision = decisions[key] else {
            return nil
        }
        guard AbTestConditionMatcher.AB_TEST_MATCHED_REASONS.contains(decision.reason) else {
            return false
        }
        return valueOperatorMatcher.matches(userValue: decision.variation, match: condition.match)
    }

    /// 이미 평가된 기능 플래그 결정을 재사용해 조건 매칭 여부를 재현한다. (`FeatureFlagConditionMatcher`와 동일 규칙)
    private func featureFlagMatched(condition: Target.Condition, decisions: [Experiment.Key: FeatureFlagDecision]) -> Bool? {
        guard let key = Experiment.Key(condition.key.name), let decision = decisions[key] else {
            return nil
        }
        return valueOperatorMatcher.matches(userValue: decision.isOn, match: condition.match)
    }

    // MARK: - Frequency

    func frequencyDetail(inAppMessage: InAppMessage, user: HackleUser, now: Date) -> FrequencyDetail {
        let impressions = (try? impressionStorage.get(inAppMessage: inAppMessage)) ?? []
        var caps: [CapStatus] = []

        if let frequencyCap = inAppMessage.eventTrigger.frequencyCap {
            for identifierCap in frequencyCap.identifierCaps {
                let count = impressions.filter { identifierCap.matches(user: user, timestamp: now, impression: $0) }.count
                caps.append(CapStatus(
                    label: "\(identifierCap.identifierType) 기준",
                    threshold: identifierCap.count,
                    currentCount: count,
                    isExceeded: count >= identifierCap.count
                ))
            }
            if let durationCap = frequencyCap.durationCap {
                let count = impressions.filter { durationCap.matches(user: user, timestamp: now, impression: $0) }.count
                caps.append(CapStatus(
                    label: durationLabel(durationCap.duration),
                    threshold: durationCap.count,
                    currentCount: count,
                    isExceeded: count >= durationCap.count
                ))
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let impressionDetails = impressions
            .sorted { $0.timestamp > $1.timestamp }
            .map { impression in
                ImpressionDetail(
                    identifiers: impression.identifiers.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", "),
                    timestamp: formatter.string(from: Date(timeIntervalSince1970: impression.timestamp))
                )
            }

        return FrequencyDetail(caps: caps, impressions: impressionDetails)
    }

    // MARK: - Hidden

    func hiddenDetail(inAppMessage: InAppMessage) -> HiddenDetail {
        HiddenDetail(expireAt: hiddenStorage.expireAt(inAppMessage: inAppMessage))
    }

    // MARK: - Dispatch

    func inspect(
        inAppMessage: InAppMessage,
        reason: String,
        user: HackleUser,
        now: Date,
        abTestDecisions: [Experiment.Key: Decision] = [:],
        featureFlagDecisions: [Experiment.Key: FeatureFlagDecision] = [:]
    ) -> InAppMessageDetail? {
        switch reason {
        case DecisionReason.IN_APP_MESSAGE_TARGET, DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET:
            return .target(targetDetails(
                inAppMessage: inAppMessage,
                user: user,
                abTestDecisions: abTestDecisions,
                featureFlagDecisions: featureFlagDecisions
            ))
        case DecisionReason.IN_APP_MESSAGE_FREQUENCY_CAPPED:
            return .frequency(frequencyDetail(inAppMessage: inAppMessage, user: user, now: now))
        case DecisionReason.IN_APP_MESSAGE_HIDDEN:
            return .hidden(hiddenDetail(inAppMessage: inAppMessage))
        default:
            return nil
        }
    }

    private func durationLabel(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        let day = 86_400, hour = 3_600, minute = 60
        if seconds % day == 0 { return "\(seconds / day)일 내" }
        if seconds % hour == 0 { return "\(seconds / hour)시간 내" }
        if seconds % minute == 0 { return "\(seconds / minute)분 내" }
        return "\(seconds)초 내"
    }
}
