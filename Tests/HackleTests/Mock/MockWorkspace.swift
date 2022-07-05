//
// Created by yong on 2020/12/17.
//

import Foundation
import Mockery
@testable import Hackle

class MockWorkspace: Mock, Workspace {

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

    func getContainerOrNull(containerId: Int64) -> Container? {
        call(getContainerOrNilMock, args: (containerId))
    }
}
