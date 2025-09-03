import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageEligibilityFlowFactory: Mock, InAppMessageEligibilityFlowFactory {

    lazy var triggerFlowMock = MockFunction(self, triggerFlow)

    func triggerFlow() -> InAppMessageEligibilityFlow {
        return call(triggerFlowMock, args: ())
    }

    lazy var deliverFlowMock = MockFunction(self, deliverFlow)

    func deliverFlow(reEvaluate: Bool) -> InAppMessageEligibilityFlow {
        return call(deliverFlowMock, args: reEvaluate)
    }
}
