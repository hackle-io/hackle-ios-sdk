//
//  InAppMessageMatcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/2/25.
//

import Foundation

protocol InAppMessageMatcher {
    func matches(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool
}
