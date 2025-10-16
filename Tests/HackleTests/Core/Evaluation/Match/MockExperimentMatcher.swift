//
//  MockExperimentMatcher.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import MockingKit
@testable import Hackle

class MockExperimentMatcher: Mock, ExperimentMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        call(matchesMock, args: (request, context, condition))
    }
}