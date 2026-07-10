//
//  InAppMessageMatcher.swift
//  Hackle
//

import Foundation

protocol InAppMessageMatcher {
    func matches(request: InAppMessageEligibilityEvaluateRequest, context: EvaluatorContext) throws -> Bool
}
