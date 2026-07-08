//
//  InAppMessageMatcherStub.swift
//  HackleTests
//

import Foundation
@testable import Hackle

class InAppMessageMatcherStub: InAppMessageMatcher {
    var isMatched: Bool

    init(isMatched: Bool = false) {
        self.isMatched = isMatched
    }

    func matches(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool {
        isMatched
    }
}
