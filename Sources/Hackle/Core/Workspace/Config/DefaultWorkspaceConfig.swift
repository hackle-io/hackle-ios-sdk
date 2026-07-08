import Foundation

class DefaultWorkspaceConfig: WorkspaceConfig {
    let metadata: WorkspaceMetadata
    let modifiedAt: String?
    let experiments: [Experiment]
    let featureFlags: [Experiment]
    let inAppMessages: [InAppMessage]
    private let buckets: [Bucket.Id: Bucket]
    private let eventTypes: [EventType.Key: EventType]
    private let segments: [Segment.Key: Segment]
    private let containers: [Container.Id: Container]
    private let parameterConfigurations: [ParameterConfiguration.Id: ParameterConfiguration]
    private let remoteConfigParameters: [RemoteConfigParameter.Key: RemoteConfigParameter]

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
        eventTypes: [EventType],
        segments: [Segment],
        containers: [Container],
        parameterConfigurations: [ParameterConfiguration],
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
        self.eventTypes = eventTypes.associateBy {
            $0.key
        }
        self.segments = segments.associateBy {
            $0.key
        }
        self.containers = containers.associateBy {
            $0.id
        }
        self.parameterConfigurations = parameterConfigurations.associateBy {
            $0.id
        }
        self.remoteConfigParameters = remoteConfigParameters.associateBy {
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

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType? {
        eventTypes[eventTypeKey]
    }

    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment? {
        segments[segmentKey]
    }

    func getContainerOrNil(containerId: Container.Id) -> Container? {
        containers[containerId]
    }

    func getParameterConfigurationOrNil(parameterConfigurationId: ParameterConfiguration.Id) -> ParameterConfiguration? {
        parameterConfigurations[parameterConfigurationId]
    }

    func getRemoteConfigParameterOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameter? {
        remoteConfigParameters[parameterKey]
    }

    func getInAppMessageOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessage? {
        _inAppMessages[inAppMessageKey]
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
        }

        let featureFlags = dto.featureFlags.compactMap { it in
            it.toExperimentOrNil(type: .featureFlag, parameterConfigurations: parameterConfigurationsById)
        }

        let buckets = dto.buckets.map { it in
            it.toBucket()
        }

        let eventTypes = dto.events.map { it in
            it.toEventType()
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
        }

        return DefaultWorkspaceConfig(
            id: workspaceId,
            environmentId: environmentId,
            modifiedAt: modifiedAt,
            experiments: experiments,
            featureFlags: featureFlags,
            buckets: buckets,
            eventTypes: eventTypes,
            segments: segments,
            containers: containers,
            parameterConfigurations: parameterConfigurations,
            remoteConfigParameters: remoteConfigParameters,
            inAppMessages: inAppMessages
        )
    }
}
