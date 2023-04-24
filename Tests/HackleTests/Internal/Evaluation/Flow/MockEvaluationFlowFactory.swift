//
//  MockEvaluationFlowFactory.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Mockery
@testable import Hackle

class MockEvaluationFlowFactory: Mock, EvaluationFlowFactory {

    let remoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer = MockRemoteConfigTargetRuleDeterminer()

    lazy var getFlowMock = MockFunction(self, getFlow)

    func getFlow(experimentType: ExperimentType) -> EvaluationFlow {
        call(getFlowMock, args: experimentType)
    }
}