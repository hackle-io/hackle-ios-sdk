//
//  InAppMessageTargetMatcher.swift
//  Hackle
//

import Foundation

class InAppMessageTargetMatcher: InAppMessageMatcher {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func matches(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool {
        let targets = request.inAppMessageConfig.targetContext.targets
        return try targetMatcher.anyMatches(request: request, context: context, targets: targets)
    }
}
