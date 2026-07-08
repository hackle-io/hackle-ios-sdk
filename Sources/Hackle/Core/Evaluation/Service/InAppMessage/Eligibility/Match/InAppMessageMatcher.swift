//
//  InAppMessageMatcher.swift
//  Hackle
//

import Foundation

protocol InAppMessageMatcher {
    func matches(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool
}
