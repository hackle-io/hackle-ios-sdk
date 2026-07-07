//

import Foundation

protocol Workspace {
    var id: Int64 { get }

    var environmentId: Int64 { get }

    var experiments: [Experiment] { get }

    var featureFlags: [Experiment] { get }

    var inAppMessages: [InAppMessage] { get }

    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment?

    func getFeatureFlagOrNil(featureKey: Experiment.Key) -> Experiment?

    func getBucketOrNil(bucketId: Bucket.Id) -> Bucket?

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType?

    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment?

    func getContainerOrNil(containerId: Container.Id) -> Container?

    func getParameterConfigurationOrNil(parameterConfigurationId: ParameterConfiguration.Id) -> ParameterConfiguration?

    func getRemoteConfigParameterOrNil(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameter?

    func getInAppMessageOrNil(inAppMessageKey: InAppMessage.Key) -> InAppMessage?
}
