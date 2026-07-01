//
//  InAppMessageUserOverrideMatcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/2/25.
//

import Foundation

class InAppMessageUserOverrideMatcher: InAppMessageMatcher {
    func matches(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool {
        return request.inAppMessage.targetContext.overrides.contains { it in
            isUserOverridden(request: request, userOverride: it)
        }
    }

    private func isUserOverridden(request: InAppMessageEligibilityLocalEvaluateRequest, userOverride: InAppMessage.UserOverride) -> Bool {
        guard let identifier = request.user.identifiers[userOverride.identifierType] else {
            return false
        }
        return userOverride.identifiers.contains(identifier)
    }
}
