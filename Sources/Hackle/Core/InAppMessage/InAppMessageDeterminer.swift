//
//  InAppMessageTriggerDeterminer.swift
//  Hackle
//
//  Created by yong on 2023/06/07.
//

import Foundation

protocol InAppMessageDeterminer {
    func determineOrNull(event: UserEvent) throws -> InAppMessageContext?
}

class DefaultInAppMessageDeterminer: InAppMessageDeterminer {

    private let workspaceFetcher: WorkspaceFetcher
    private let eventMatcher: InAppMessageEventMatcher
    private let core: HackleCore

    init(workspaceFetcher: WorkspaceFetcher, eventMatcher: InAppMessageEventMatcher, core: HackleCore) {
        self.workspaceFetcher = workspaceFetcher
        self.eventMatcher = eventMatcher
        self.core = core
    }

    func determineOrNull(event: UserEvent) throws -> InAppMessageContext? {

        guard let workspace = workspaceFetcher.fetch() else {
            return nil
        }

        for inAppMessage in workspace.inAppMessages {
            guard try eventMatcher.matches(workspace: workspace, inAppMessage: inAppMessage, event: event),
                  let context = context(inAppMessage: inAppMessage, event: event)
            else {
                continue
            }
            return context
        }

        return nil
    }

    private func context(inAppMessage: InAppMessage, event: UserEvent) -> InAppMessageContext? {
        let decision = core.tryInAppMessage(inAppMessageKey: inAppMessage.key, user: event.user)
        guard let inAppMessage = decision.inAppMessage, let message = decision.message else {
            return nil
        }

        let properties = PropertiesBuilder()
            .add("decision_reason", decision.reason)
            .build()

        return InAppMessageContext(inAppMessage: inAppMessage, message: message, properties: properties)
    }
}


protocol InAppMessageEventMatcher {
    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvent) throws -> Bool
}

class DefaultInAppMessageEventMatcher: InAppMessageEventMatcher {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvent) throws -> Bool {
        guard let trackEvent = event as? UserEvents.Track else {
            return false
        }

        return try matches(workspace: workspace, inAppMessage: inAppMessage, event: trackEvent)
    }

    private func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> Bool {
        try inAppMessage.triggerRules.contains { it in
            try ruleMatches(workspace: workspace, event: event, rule: it)
        }
    }

    private func ruleMatches(workspace: Workspace, event: UserEvents.Track, rule: InAppMessage.TriggerRule) throws -> Bool {
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
