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

    lazy var getEventTypeOrNilMock = MockFunction(self, getEventTypeOrNil)

    func getEventTypeOrNil(eventTypeKey: EventType.Key) -> EventType? {
        call(getEventTypeOrNilMock, args: eventTypeKey)
    }
}
