//
//  InAppMessageHiddenMatcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/2/25.
//

import Foundation

class InAppMessageHiddenMatcher: InAppMessageMatcher {

    private let storage: InAppMessageHiddenStorage

    init(storage: InAppMessageHiddenStorage) {
        self.storage = storage
    }

    func matches(request: EvaluateRequest, context: EvaluatorContext) throws -> Bool {
        storage.exist(inAppMessage: request.inAppMessage, now: request.timestamp)
    }
}
