import Foundation
import Mockery
@testable import Hackle

class MockExperimentFlowFactory: Mock, ExperimentFlowFactory {

    lazy var getMock = MockFunction(self, get)

    func get(experimentType: ExperimentType) -> ExperimentFlow {
        return call(getMock, args: experimentType)
    }
}
