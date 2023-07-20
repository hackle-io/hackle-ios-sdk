//
//  InAppMessageEventTriggerDeterminer.swift
//  Hackle
//
//  Created by yong on 2023/07/20.
//

import Foundation


protocol InAppMessageEventTriggerDeterminer {
    func isTriggerTarget(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> Bool
}

class InAppMessageEventTriggerRuleDeterminer: InAppMessageEventTriggerDeterminer {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func isTriggerTarget(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> Bool {
        try inAppMessage.eventTrigger.rules.contains { it in
            try ruleMatches(workspace: workspace, event: event, rule: it)
        }
    }

    private func ruleMatches(workspace: Workspace, event: UserEvents.Track, rule: InAppMessage.EventTrigger.Rule) throws -> Bool {
        guard event.event.key == rule.eventKey else {
            return false
        }
        let request = EvaluatorRequest(workspace: workspace, user: event.user, event: event)
        return try targetMatcher.anyMatches(request: request, context: Evaluators.context(), targets: rule.targets)
    }

    private class EvaluatorRequest: EvaluatorEventRequest {
        let key: EvaluatorKey
        let workspace: Workspace
        let user: HackleUser
        let event: UserEvent

        init(workspace: Workspace, user: HackleUser, event: UserEvent) {
            self.key = EvaluatorKey(type: .event, id: event.timestamp.epochMillis)
            self.workspace = workspace
            self.user = user
            self.event = event
        }
    }
}

class InAppMessageEventTriggerFrequencyCapDeterminer: InAppMessageEventTriggerDeterminer {
    private let storage: InAppMessageImpressionStorage

    init(storage: InAppMessageImpressionStorage) {
        self.storage = storage
    }

    func isTriggerTarget(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> Bool {
        guard let frequencyCap = inAppMessage.eventTrigger.frequencyCap else {
            return true
        }

        let contexts = createMatchContexts(frequencyCap: frequencyCap)
        if contexts.count == 0 {
            return true
        }

        let impressions = try storage.get(inAppMessage: inAppMessage)
        for impression in impressions {
            for context in contexts {
                if context.matches(event: event, impression: impression) {
                    return false
                }
            }
        }
        return true
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


    private class MatchContext {
        private let predicate: FrequencyCapPredicate
        private var matchCount: Int64 = 0

        init(predicate: FrequencyCapPredicate) {
            self.predicate = predicate
        }

        func matches(event: UserEvent, impression: InAppMessageImpression) -> Bool {
            if predicate.matches(event: event, impression: impression) {
                matchCount += 1
            }

            return matchCount >= predicate.thresholdCount
        }
    }

}

protocol FrequencyCapPredicate {
    var thresholdCount: Int64 { get }
    func matches(event: UserEvent, impression: InAppMessageImpression) -> Bool
}

extension InAppMessage.EventTrigger.IdentifierCap: FrequencyCapPredicate {
    var thresholdCount: Int64 {
        count
    }

    func matches(event: UserEvent, impression: InAppMessageImpression) -> Bool {
        guard let userIdentifier = event.user.identifiers[identifierType] else {
            return false
        }
        guard let impressionIdentifier = impression.identifiers[identifierType] else {
            return false
        }
        return impressionIdentifier == userIdentifier
    }
}

extension InAppMessage.EventTrigger.DurationCap: FrequencyCapPredicate {
    var thresholdCount: Int64 {
        count
    }

    func matches(event: UserEvent, impression: InAppMessageImpression) -> Bool {
        (event.timestamp.timeIntervalSince1970 - impression.timestamp) <= duration
    }
}
