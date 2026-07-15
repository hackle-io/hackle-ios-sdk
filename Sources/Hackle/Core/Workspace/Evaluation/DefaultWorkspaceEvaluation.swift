import Foundation

final class DefaultWorkspaceEvaluation: WorkspaceEvaluation, @unchecked Sendable {

    // Metadata
    let id: Int64
    let environmentId: Int64
    let evaluatedAt: Int64
    let modifiedAt: String?
    let fullEvaluatedAt: Int64?

    // Entity
    let experimentResults: [ExperimentRemoteEvaluateResult]
    let featureFlagResults: [ExperimentRemoteEvaluateResult]
    let remoteConfigParameterResults: [RemoteConfigParameterRemoteEvaluateResult]
    let inAppMessageResults: [InAppMessageEligibilityRemoteEvaluateResult]

    private let _experiments: [Experiment.Key: ExperimentRemoteEvaluateResult]
    private let _featureFlags: [Experiment.Key: ExperimentRemoteEvaluateResult]
    private let _remoteConfigParameters: [RemoteConfigParameter.Key: RemoteConfigParameterRemoteEvaluateResult]
    private let _inAppMessages: [InAppMessage.Key: InAppMessageEligibilityRemoteEvaluateResult]

    var metadata: WorkspaceMetadata {
        WorkspaceMetadata(id: id, environmentId: environmentId)
    }

    init(
        id: Int64,
        environmentId: Int64,
        evaluatedAt: Int64,
        modifiedAt: String?,
        fullEvaluatedAt: Int64?,
        experimentResults: [ExperimentRemoteEvaluateResult],
        featureFlagResults: [ExperimentRemoteEvaluateResult],
        remoteConfigParameterResults: [RemoteConfigParameterRemoteEvaluateResult],
        inAppMessageResults: [InAppMessageEligibilityRemoteEvaluateResult]
    ) {
        self.id = id
        self.environmentId = environmentId
        self.evaluatedAt = evaluatedAt
        self.modifiedAt = modifiedAt
        self.fullEvaluatedAt = fullEvaluatedAt
        self.experimentResults = experimentResults
        self.featureFlagResults = featureFlagResults
        self.remoteConfigParameterResults = remoteConfigParameterResults
        self.inAppMessageResults = inAppMessageResults
        self._experiments = experimentResults.associateBy { it in
            it.key
        }
        self._featureFlags = featureFlagResults.associateBy { it in
            it.key
        }
        self._remoteConfigParameters = remoteConfigParameterResults.associateBy { it in
            it.key
        }
        self._inAppMessages = inAppMessageResults.associateBy { it in
            it.key
        }
    }

    func getExperimentResultOrNil(experimentKey: Experiment.Key) -> ExperimentRemoteEvaluateResult? {
        _experiments[experimentKey]
    }

    func getFeatureFlagResultOrNil(featureKey: Experiment.Key) -> ExperimentRemoteEvaluateResult? {
        _featureFlags[featureKey]
    }

    func getRemoteConfigParameterResultOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameterRemoteEvaluateResult? {
        _remoteConfigParameters[parameterKey]
    }

    func getInAppMessageResultOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessageEligibilityRemoteEvaluateResult? {
        _inAppMessages[inAppMessageKey]
    }

    func result(entity: Entity) -> RemoteEvaluateResult? {
        let results: [RemoteEvaluateResult]
        switch entity.serviceType {
        case .abTest:
            results = experimentResults
        case .featureFlag:
            results = featureFlagResults
        case .remoteConfig:
            results = remoteConfigParameterResults
        case .inAppMessage:
            results = inAppMessageResults
        }
        return results.first { it in
            it.id == entity.id
        }
    }

    func toProperties() -> [String: Any] {
        PropertiesBuilder()
            .add("config_modified_at", modifiedAt)
            .add("remote_evaluated_at", evaluatedAt)
            .add("remote_full_evaluated_at", fullEvaluatedAt)
            .build()
    }

    static func from(dto: WorkspaceEvaluationDto, fullEvaluatedAt: Int64?) -> DefaultWorkspaceEvaluation {
        var experiments = [ExperimentRemoteEvaluateResult]()
        var featureFlags = [ExperimentRemoteEvaluateResult]()
        var remoteConfigParameters = [RemoteConfigParameterRemoteEvaluateResult]()
        var inAppMessages = [InAppMessageEligibilityRemoteEvaluateResult]()

        for result in dto.results {
            guard let serviceType: ServiceType = Enums.parseOrNil(rawValue: result.type) else {
                continue
            }
            switch serviceType {
            case .abTest:
                if let it = result.experiment?.toResult(type: .abTest) {
                    experiments.append(it)
                }
            case .featureFlag:
                if let it = result.featureFlag?.toResult(type: .featureFlag) {
                    featureFlags.append(it)
                }
            case .remoteConfig:
                if let it = result.remoteConfig?.toResultOrNil() {
                    remoteConfigParameters.append(it)
                }
            case .inAppMessage:
                if let it = result.inAppMessage?.toResultOrNil() {
                    inAppMessages.append(it)
                }
            }
        }
        return DefaultWorkspaceEvaluation(
            id: dto.workspace.id,
            environmentId: dto.workspace.environment.id,
            evaluatedAt: dto.metadata.evaluatedAt,
            modifiedAt: dto.metadata.config.modifiedAt,
            fullEvaluatedAt: fullEvaluatedAt,
            experimentResults: experiments.sorted { $0.order < $1.order },
            featureFlagResults: featureFlags.sorted { $0.order < $1.order },
            remoteConfigParameterResults: remoteConfigParameters,
            inAppMessageResults: inAppMessages.sorted { $0.order < $1.order }
        )
    }
}
