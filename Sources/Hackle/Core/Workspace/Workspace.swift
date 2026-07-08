import Foundation

struct WorkspaceMetadata {
    let id: Int64
    let environmentId: Int64
}

protocol Workspace {
    var metadata: WorkspaceMetadata { get }

    var experiments: [Experiment] { get }

    var featureFlags: [Experiment] { get }

    var remoteConfigParameters: [RemoteConfigParameter] { get }

    var inAppMessages: [InAppMessage] { get }

    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment?

    func getFeatureFlagOrNil(featureKey: Experiment.Key) -> Experiment?

    func getRemoteConfigParameterOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameter?

    func getInAppMessageOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessage?

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType? // Task 7에서 제거

    func toProperties() -> [String: Any]
}
