import Foundation
@testable import Hackle

class MockWorkspaceEvaluation: WorkspaceEvaluation {
    var metadata: WorkspaceMetadata = WorkspaceMetadata(id: 1, environmentId: 1)
    var evaluatedAt: Int64 = 0
    var modifiedAt: String? = nil
    var experimentResults: [ExperimentRemoteEvaluateResult] = []
    var featureFlagResults: [ExperimentRemoteEvaluateResult] = []
    var remoteConfigParameterResults: [RemoteConfigParameterRemoteEvaluateResult] = []
    var inAppMessageResults: [InAppMessageEligibilityRemoteEvaluateResult] = []

    func getExperimentResultOrNil(experimentKey: Experiment.Key) -> ExperimentRemoteEvaluateResult? {
        experimentResults.first { $0.key == experimentKey }
    }

    func getFeatureFlagResultOrNil(featureKey: Experiment.Key) -> ExperimentRemoteEvaluateResult? {
        featureFlagResults.first { $0.key == featureKey }
    }

    func getRemoteConfigParameterResultOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameterRemoteEvaluateResult? {
        remoteConfigParameterResults.first { $0.key == parameterKey }
    }

    func getInAppMessageResultOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessageEligibilityRemoteEvaluateResult? {
        inAppMessageResults.first { $0.key == inAppMessageKey }
    }

    func result(entity: Entity) -> RemoteEvaluateResult? {
        var all: [RemoteEvaluateResult] = []
        all.append(contentsOf: experimentResults)
        all.append(contentsOf: featureFlagResults)
        all.append(contentsOf: remoteConfigParameterResults)
        all.append(contentsOf: inAppMessageResults)
        return all.first { $0.entityKey == entity.entityKey }
    }
}

class MockWorkspaceEvaluationFetcher: WorkspaceEvaluationFetcher {
    var returns: WorkspaceEvaluation? = nil
    func workspace(user: HackleUser) -> WorkspaceEvaluation? {
        returns
    }
}

func experimentRemoteResult(
    id: Int64 = 1,
    key: Int64 = 10,
    type: ExperimentType = .abTest,
    variation: Variation = VariationEntity(id: 42, key: "B", isDropped: false, parameterConfiguration: nil),
    reason: String = DecisionReason.OVERRIDDEN,
    references: [Entity] = []
) -> ExperimentRemoteEvaluateResult {
    ExperimentRemoteEvaluateResult(
        id: id, key: key, version: 1, type: type, executionVersion: 1,
        variation: variation, reason: reason, references: references
    )
}

func remoteConfigRemoteResult(
    id: Int64 = 2,
    key: String = "rc_key",
    value: RemoteConfigParameter.Value? = RemoteConfigParameterEntity.Value(id: 7, rawValue: HackleValue(value: "v")),
    reason: String = DecisionReason.TARGET_RULE_MATCH
) -> RemoteConfigParameterRemoteEvaluateResult {
    RemoteConfigParameterRemoteEvaluateResult(id: id, key: key, type: .string, value: value, reason: reason, references: [])
}

func inAppMessageLayoutRemoteResult(
    id: Int64 = 5,
    key: Int64 = 50,
    reason: String = DecisionReason.IN_APP_MESSAGE_TARGET
) -> InAppMessageLayoutRemoteEvaluateResult {
    let iam = InAppMessageEntity.create()
    return InAppMessageLayoutRemoteEvaluateResult(
        id: id, key: key,
        period: iam.period, timetable: iam.timetable, eventTrigger: iam.eventTrigger,
        evaluateContext: iam.evaluateContext, messageContext: iam.messageContext,
        message: iam.messageContext.messages[0],
        reason: reason,
        references: []
    )
}

func inAppMessageEligibilityRemoteResult(
    id: Int64 = 5,
    key: Int64 = 50,
    isEligible: Bool = true,
    reason: String = DecisionReason.IN_APP_MESSAGE_TARGET,
    layout: InAppMessageLayoutRemoteEvaluateResult? = nil
) -> InAppMessageEligibilityRemoteEvaluateResult {
    let iam = InAppMessageEntity.create()
    return InAppMessageEligibilityRemoteEvaluateResult(
        id: id, key: key,
        period: iam.period, timetable: iam.timetable, eventTrigger: iam.eventTrigger,
        evaluateContext: iam.evaluateContext, messageContext: iam.messageContext,
        isEligible: isEligible,
        reason: reason,
        references: [],
        layout: layout ?? inAppMessageLayoutRemoteResult(id: id, key: key)
    )
}
