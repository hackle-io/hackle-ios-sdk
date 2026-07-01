import Foundation

protocol WorkspaceConfig: Workspace {
    func getExperimentConfigOrNil(experimentKey: Experiment.Key) -> ExperimentConfig?
    func getFeatureFlagConfigOrNil(featureKey: Experiment.Key) -> ExperimentConfig?
    func getRemoteConfigParameterConfigOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameterConfig?
    func getInAppMessageConfigOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessageConfig?
    // Bucket/Segment/Container 조회는 base Workspace(getBucketOrNil 등)에 이미 존재 → 재선언하지 않음
}
