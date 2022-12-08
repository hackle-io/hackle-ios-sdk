//
// Created by yong on 2020/12/17.
//

import Foundation
import Mockery
@testable import Hackle

class MockWorkspace: Mock, Workspace {
    let experiments: [Experiment]
    let featureFlags: [Experiment]

    init(experiments: [Experiment] = [], featureFlags: [Experiment] = []) {
        self.experiments = experiments
        self.featureFlags = featureFlags
        super.init()
    }

    lazy var getExperimentOrNilMock = MockFunction(self, getExperimentOrNil)

    func getExperimentOrNil(experimentKey: Experiment.Key) -> Experiment? {
        call(getExperimentOrNilMock, args: experimentKey)
    }

    lazy var getFeatureFlagOrNilMock = MockFunction(self, getFeatureFlagOrNil)

    func getFeatureFlagOrNil(featureKey: Experiment.Key) -> Experiment? {
        call(getFeatureFlagOrNilMock, args: featureKey)
    }

    lazy var getBucketOrNilMock = MockFunction(self, getBucketOrNil)

    func getBucketOrNil(bucketId: Bucket.Id) -> Bucket? {
        call(getBucketOrNilMock, args: bucketId)
    }

    lazy var getEventTypeOrNilMock = MockFunction(self, getEventTypeOrNil)

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType? {
        call(getEventTypeOrNilMock, args: eventTypeKey)
    }

    lazy var getSegmentOrNilMock = MockFunction(self, getSegmentOrNil)

    func getSegmentOrNil(segmentKey: Segment.Key) -> Segment? {
        call(getSegmentOrNilMock, args: (segmentKey))
    }

    lazy var getContainerOrNilMock = MockFunction(self, getContainerOrNil)

    func getContainerOrNil(containerId: Container.Id) -> Container? {
        call(getContainerOrNilMock, args: containerId)
    }

    lazy var getParameterConfigurationOrNilMock = MockFunction(self, getParameterConfigurationOrNil)

    func getParameterConfigurationOrNil(parameterConfigurationId: ParameterConfiguration.Id) -> ParameterConfiguration? {
        call(getParameterConfigurationOrNilMock, args: parameterConfigurationId)
    }

    lazy var getRemoteConfigParameterMock = MockFunction(self, getRemoteConfigParameter)

    func getRemoteConfigParameter(parameterKey: RemoteConfigParameter.Key) -> RemoteConfigParameter? {
        call(getRemoteConfigParameterMock, args: parameterKey)
    }
}
