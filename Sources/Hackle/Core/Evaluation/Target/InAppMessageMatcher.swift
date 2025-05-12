//
//  InAppMessageMatcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/2/25.
//

import Foundation

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

class InAppMessageFrequencyCapMatcher: InAppMessageMatcher {
    
    private let storage: InAppMessageImpressionStorage
    
    init(storage: InAppMessageImpressionStorage) {
        self.storage = storage
    }
    
    func matches(request: InAppMessageRequest, context: EvaluatorContext) throws -> Bool {
        return try isFrequencyCapped(inAppMessage: request.inAppMessage, user: request.user, timestamp: request.timestamp)
    }
    
    private func isFrequencyCapped(inAppMessage: InAppMessage, user: HackleUser, timestamp: Date) throws -> Bool {
        guard let frequencyCap = inAppMessage.eventTrigger.frequencyCap else {
            return false
        }
        
        let contexts = createMatchContexts(frequencyCap: frequencyCap)
        if contexts.count == 0 {
            return false
        }

        let impressions = try storage.get(inAppMessage: inAppMessage)
        for impression in impressions {
            for context in contexts {
                if context.match(user: user, timestamp: timestamp, impression: impression) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func createMatchContexts(frequencyCap: InAppMessage.EventTrigger.FrequencyCap) -> [MatchContext] {
        var contexts = [MatchContext]()

        for identifierCap in frequencyCap.identifierCaps {
            contexts.append(MatchContext(predicate: identifierCap))
        }

        if let durationCap = frequencyCap.durationCap {
            contexts.append(MatchContext(predicate: durationCap))
        }
        return contexts
    }
}

extension InAppMessageFrequencyCapMatcher {
    fileprivate class MatchContext {
        
        private let predicate: FrequencyCapPredicate
        private var matchCount: Int = 0
        
        init(predicate: FrequencyCapPredicate) {
            self.predicate = predicate
        }
        
        func match(user: HackleUser, timestamp: Date, impression: InAppMessageImpression) -> Bool {
            if predicate.matches(user: user, timestamp: timestamp, impression: impression) {
                matchCount += 1
            }

            return matchCount >= predicate.thresholdCount
        }
    }
    
    protocol FrequencyCapPredicate {
        var thresholdCount: Int64 { get }
        func matches(user: HackleUser, timestamp: Date, impression: InAppMessageImpression) -> Bool
    }
}



extension InAppMessage.EventTrigger.IdentifierCap: InAppMessageFrequencyCapMatcher.FrequencyCapPredicate {
    var thresholdCount: Int64 {
        count
    }

    func matches(user: HackleUser, timestamp: Date, impression: InAppMessageImpression) -> Bool {
        guard let userIdentifier = user.identifiers[identifierType],
              let impressionIdentifier = impression.identifiers[identifierType] else {
            return false
        }

        return userIdentifier == impressionIdentifier
    }
}

extension InAppMessage.EventTrigger.DurationCap: InAppMessageFrequencyCapMatcher.FrequencyCapPredicate {
    var thresholdCount: Int64 {
        count
    }

    func matches(user: HackleUser, timestamp: Date, impression: InAppMessageImpression) -> Bool {
        (timestamp.timeIntervalSince1970 - impression.timestamp) <= duration
    }
}
