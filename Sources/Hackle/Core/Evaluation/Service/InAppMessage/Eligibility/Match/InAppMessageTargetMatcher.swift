//
//  InAppMessageTargetMatcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/2/25.
//

import Foundation

class InAppMessageTargetMatcher: InAppMessageMatcher {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func matches(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool {
        let targets = request.inAppMessage.targetContext.targets
        return try targetMatcher.anyMatches(request: request, context: context, targets: targets)
    }
}
