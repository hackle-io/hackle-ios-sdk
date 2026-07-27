import Foundation

protocol WorkspaceConfig: Workspace {
    var modifiedAt: String? { get }

    var experimentConfigs: [ExperimentConfig] { get }
    var featureFlagConfigs: [ExperimentConfig] { get }

    func getExperimentConfigOrNil(experimentKey: Experiment.Key) -> ExperimentConfig?
    func getFeatureFlagConfigOrNil(featureKey: Experiment.Key) -> ExperimentConfig?
    func getRemoteConfigParameterConfigOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameterConfig?
    func getInAppMessageConfigOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessageConfig?

    func getBucketOrNil(bucketId: Bucket.Id) -> Bucket?
    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment?
    func getContainerOrNil(containerId: Container.Id) -> Container?
}
