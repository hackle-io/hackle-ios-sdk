import Foundation

protocol WorkspaceEvaluation: Workspace {

    var evaluatedAt: Int64 { get }
    var modifiedAt: String? { get }

    var experimentResults: [ExperimentRemoteEvaluateResult] { get }
    var featureFlagResults: [ExperimentRemoteEvaluateResult] { get }
    var remoteConfigParameterResults: [RemoteConfigParameterRemoteEvaluateResult] { get }
    var inAppMessageResults: [InAppMessageEligibilityRemoteEvaluateResult] { get }

    func getExperimentResultOrNil(experimentKey: Experiment.Key) -> ExperimentRemoteEvaluateResult?
    func getFeatureFlagResultOrNil(featureKey: Experiment.Key) -> ExperimentRemoteEvaluateResult?
    func getRemoteConfigParameterResultOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameterRemoteEvaluateResult?
    func getInAppMessageResultOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessageEligibilityRemoteEvaluateResult?

    func result(entity: Entity) -> RemoteEvaluateResult?
}

extension WorkspaceEvaluation {

    var experiments: [Experiment] {
        experimentResults
    }

    var featureFlags: [Experiment] {
        featureFlagResults
    }

    var remoteConfigParameters: [RemoteConfigParameter] {
        remoteConfigParameterResults
    }

    var inAppMessages: [InAppMessage] {
        inAppMessageResults
    }

    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment? {
        getExperimentResultOrNil(experimentKey: experimentKey)
    }

    func getFeatureFlagOrNil(featureKey: Experiment.Key) -> Experiment? {
        getFeatureFlagResultOrNil(featureKey: featureKey)
    }

    func getRemoteConfigParameterOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameter? {
        getRemoteConfigParameterResultOrNil(parameterKey: parameterKey)
    }

    func getInAppMessageOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessage? {
        getInAppMessageResultOrNil(inAppMessageKey: inAppMessageKey)
    }
}
