//
//  InAppMessageResolver.swift
//  Hackle
//
//  Created by yong on 2023/06/01.
//

import Foundation


protocol InAppMessageResolver {
    func resolve(request: InAppMessageRequest, context: EvaluatorContext) throws -> InAppMessage.Message
}

class DefaultInAppMessageResolver: InAppMessageResolver {
    func resolve(request: InAppMessageRequest, context: EvaluatorContext) throws -> InAppMessage.Message {

        let inAppMessage = request.inAppMessage
        let lang = inAppMessage.messageContext.defaultLang

        guard let message = inAppMessage.messageContext.messages.first(where: { message in
            message.lang == lang
        })
        else {
            throw HackleError.error("InAppMessage must be decided [\(inAppMessage.id)]")
        }

        return message
    }
}


protocol InAppMessageMatcher {
    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool
}

class InAppMessageUserOverrideMatcher: InAppMessageMatcher {
    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool {
        let userOverrides = request.inAppMessage.targetContext.overrides
        if userOverrides.isEmpty {
            return false
        }
        return userOverrides.contains { it in
            isUserOverridden(request: request, userOverride: it)
        }
    }

    private func isUserOverridden(request: InAppMessageRequest, userOverride: InAppMessage.UserOverride) -> Bool {
        guard let identifier = request.user.identifiers[userOverride.identifierType] else {
            return false
        }
        return userOverride.identifiers.contains(identifier)
    }
}

class InAppMessageTargetMatcher: InAppMessageMatcher {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool {
        let targets = request.inAppMessage.targetContext.targets
        if targets.isEmpty {
            return true
        }

        return try targets.contains { it in
            try targetMatcher.matches(request: request, context: context, target: it)
        }
    }
}


class InAppMessageHiddenMatcher: InAppMessageMatcher {

    private let storage: InAppMessageHiddenStorage

    init(storage: InAppMessageHiddenStorage) {
        self.storage = storage
    }

    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool {
        storage.exist(inAppMessage: request.inAppMessage, now: request.timestamp)
    }
}
