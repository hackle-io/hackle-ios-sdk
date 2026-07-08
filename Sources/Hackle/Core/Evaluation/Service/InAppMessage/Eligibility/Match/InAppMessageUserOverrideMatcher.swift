//
//  InAppMessageUserOverrideMatcher.swift
//  Hackle
//

import Foundation

class InAppMessageUserOverrideMatcher {
    func matches(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool {
        return request.inAppMessageConfig.targetContext.overrides.contains { it in
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
