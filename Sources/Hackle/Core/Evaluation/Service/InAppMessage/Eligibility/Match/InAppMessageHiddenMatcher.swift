//
//  InAppMessageHiddenMatcher.swift
//  Hackle
//

import Foundation

class InAppMessageHiddenMatcher: InAppMessageMatcher {

    private let storage: InAppMessageHiddenStorage

    init(storage: InAppMessageHiddenStorage) {
        self.storage = storage
    }

    func matches(request: InAppMessageEligibilityEvaluateRequest, context: EvaluatorContext) throws -> Bool {
        storage.exist(inAppMessage: request.inAppMessage, now: request.timestamp)
    }
}
