//
//  InAppMessageMatcherStub.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
@testable import Hackle

class InAppMessageMatcherStub: InAppMessageMatcher {
    var isMatched: Bool

    init(isMatched: Bool = false) {
        self.isMatched = isMatched
    }

    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool {
        isMatched
    }
}
