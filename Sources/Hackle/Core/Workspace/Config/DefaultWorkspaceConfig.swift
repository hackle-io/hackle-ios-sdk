import Foundation

class DefaultWorkspaceConfig: WorkspaceConfig {
    let metadata: WorkspaceMetadata
    let modifiedAt: String?
    let experiments: [Experiment]
    let featureFlags: [Experiment]
    let inAppMessages: [InAppMessage]
    private let buckets: [Bucket.Id: Bucket]
    private let segments: [Segment.Key: Segment]
    private let containers: [Container.Id: Container]
    private let _remoteConfigParameters: [RemoteConfigParameter.Key: RemoteConfigParameter]

    private let _experiments: [Experiment.Key: Experiment]
    private let _featureFlags: [Experiment.Key: Experiment]
    private let _inAppMessages: [InAppMessage.Key: InAppMessage]

    init(
        id: Int64,
        environmentId: Int64,
        modifiedAt: String? = nil,
        experiments: [Experiment],
        featureFlags: [Experiment],
        buckets: [Bucket],
        segments: [Segment],
        containers: [Container],
        remoteConfigParameters: [RemoteConfigParameter],
        inAppMessages: [InAppMessage]
    ) {
        self.metadata = WorkspaceMetadata(id: id, environmentId: environmentId)
        self.modifiedAt = modifiedAt
        self.experiments = experiments
        self.featureFlags = featureFlags
        self.inAppMessages = inAppMessages
        self.buckets = buckets.associateBy {
            $0.id
        }
        self.segments = segments.associateBy {
            $0.key
        }
        self.containers = containers.associateBy {
            $0.id
        }
        self._remoteConfigParameters = remoteConfigParameters.associateBy {
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

    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment? {
        segments[segmentKey]
    }

    func getContainerOrNil(containerId: Container.Id) -> Container? {
        containers[containerId]
    }

    func getRemoteConfigParameterOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameter? {
        _remoteConfigParameters[parameterKey]
    }

    func getInAppMessageOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessage? {
        _inAppMessages[inAppMessageKey]
    }

    var remoteConfigParameters: [RemoteConfigParameter] {
        Array(_remoteConfigParameters.values)
    }

    func getExperimentConfigOrNil(experimentKey: Experiment.Key) -> ExperimentConfig? {
        getExperimentOrNil(experimentKey: experimentKey) as? ExperimentConfig
    }

    func getFeatureFlagConfigOrNil(featureKey: Experiment.Key) -> ExperimentConfig? {
        getFeatureFlagOrNil(featureKey: featureKey) as? ExperimentConfig
    }

    func getRemoteConfigParameterConfigOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameterConfig? {
        getRemoteConfigParameterOrNil(parameterKey: parameterKey) as? RemoteConfigParameterConfig
    }

    func getInAppMessageConfigOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessageConfig? {
        getInAppMessageOrNil(inAppMessageKey: inAppMessageKey) as? InAppMessageConfig
    }

    static func from(dto: WorkspaceConfigDto, modifiedAt: String?) -> WorkspaceConfig {
        let workspaceId = dto.workspace.id
        let environmentId = dto.workspace.environment.id

        let parameterConfigurations = dto.parameterConfigurations.map { it in
            it.toParameterConfiguration()
        }
        let parameterConfigurationsById = parameterConfigurations.associateBy { it in
            it.id
        }

        let experiments = dto.experiments.compactMap { it in
            it.toExperimentOrNil(type: .abTest, parameterConfigurations: parameterConfigurationsById)
        }.sorted { $0.order < $1.order }

        let featureFlags = dto.featureFlags.compactMap { it in
            it.toExperimentOrNil(type: .featureFlag, parameterConfigurations: parameterConfigurationsById)
        }.sorted { $0.order < $1.order }

        let buckets = dto.buckets.map { it in
            it.toBucket()
        }

        let segments = dto.segments.compactMap { it in
            it.toSegmentOrNil()
        }

        let containers = dto.containers.map { it in
            it.toContainer()
        }

        let remoteConfigParameters = dto.remoteConfigParameters.compactMap { it in
            it.toRemoteConfigParameterOrNil()
        }

        let inAppMessages = dto.inAppMessages.compactMap { it in
            it.toInAppMessageOrNil()
        }.sorted { $0.order < $1.order }

        return DefaultWorkspaceConfig(
            id: workspaceId,
            environmentId: environmentId,
            modifiedAt: modifiedAt,
            experiments: experiments,
            featureFlags: featureFlags,
            buckets: buckets,
            segments: segments,
            containers: containers,
            remoteConfigParameters: remoteConfigParameters,
            inAppMessages: inAppMessages
        )
    }
}

extension DefaultWorkspaceConfig {
    func toProperties() -> [String: Any] {
        PropertiesBuilder()
            .add("evaluation_mode", "LOCAL")
            .add("config_modified_at", modifiedAt)
            .build()
    }
}
