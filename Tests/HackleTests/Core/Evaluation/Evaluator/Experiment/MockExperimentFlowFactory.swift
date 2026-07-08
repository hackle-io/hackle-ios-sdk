import Foundation
import MockingKit
@testable import Hackle

class MockExperimentFlowFactory: Mock, ExperimentLocalEvaluationFlowFactory {

    lazy var getMock = MockFunction(self, flow)

    func flow(experimentType: ExperimentType) -> ExperimentLocalEvaluationFlow {
        return call(getMock, args: experimentType)
    }
}
