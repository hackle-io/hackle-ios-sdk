import Foundation

protocol WorkspaceConfig: Workspace {
    var modifiedAt: String? { get }

    func getExperimentConfigOrNil(experimentKey: Experiment.Key) -> ExperimentConfig?
    func getFeatureFlagConfigOrNil(featureKey: Experiment.Key) -> ExperimentConfig?
    func getRemoteConfigParameterConfigOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameterConfig?
    func getInAppMessageConfigOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessageConfig?

    func getBucketOrNil(bucketId: Bucket.Id) -> Bucket?
    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment?
    func getContainerOrNil(containerId: Container.Id) -> Container?
}

extension WorkspaceConfig {
    var experimentConfigs: [ExperimentConfig] {
        experiments.compactMap { $0 as? ExperimentConfig }
    }

    var featureFlagConfigs: [ExperimentConfig] {
        featureFlags.compactMap { $0 as? ExperimentConfig }
    }
}
