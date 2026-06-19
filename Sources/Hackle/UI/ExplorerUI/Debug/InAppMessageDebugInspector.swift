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

    func targetDetails(inAppMessage: InAppMessage, user: HackleUser) -> [TargetGroupDetail] {
        inAppMessage.targetContext.targets.enumerated().map { index, target in
            TargetGroupDetail(
                index: index + 1,
                conditions: target.conditions.map { conditionDetail(condition: $0, user: user) }
            )
        }
    }

    private func conditionDetail(condition: Target.Condition, user: HackleUser) -> ConditionDetail {
        let keyType = condition.key.type
        let isUserProperty = (keyType == .userId || keyType == .userProperty || keyType == .hackleProperty)
        let requirement = "\(condition.match.matchOperator.rawValue) [\(condition.match.values.map { $0.asString() ?? "" }.joined(separator: ", "))]"

        guard isUserProperty else {
            return ConditionDetail(
                keyType: keyType.rawValue,
                keyName: condition.key.name,
                requirement: requirement,
                userValue: nil,
                isMatched: nil,
                isUserProperty: false
            )
        }

        let resolved = try? userValueResolver.resolveOrNil(user: user, key: condition.key)
        let userValue: Any? = resolved ?? nil
        let isMatched = valueOperatorMatcher.matches(userValue: userValue, match: condition.match)
        let userValueString: String? = userValue.map { "\($0)" }
        return ConditionDetail(
            keyType: keyType.rawValue,
            keyName: condition.key.name,
            requirement: requirement,
            userValue: userValueString,
            isMatched: isMatched,
            isUserProperty: true
        )
    }
}
