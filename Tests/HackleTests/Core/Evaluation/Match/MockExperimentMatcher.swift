//
//  MockExperimentMatcher.swift
//  HackleTests
//

import Foundation
import MockingKit
@testable import Hackle

class MockExperimentMatcher: Mock, ExperimentMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(request: LocalEvaluateRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        call(matchesMock, args: (request, context, condition))
    }
}