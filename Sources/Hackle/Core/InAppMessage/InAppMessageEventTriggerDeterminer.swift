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
            try ruleMatches(workspace: workspace, event: event, inAppMessage: inAppMessage, rule: it)
        }
    }

    private func ruleMatches(
        workspace: Workspace,
        event: UserEvents.Track,
        inAppMessage: InAppMessage,
        rule: InAppMessage.EventTrigger.Rule
    ) throws -> Bool {
        guard event.event.key == rule.eventKey else {
            return false
        }
        let request = EvaluatorRequest.of(workspace: workspace, event: event, inAppMessage: inAppMessage)
        return try targetMatcher.anyMatches(request: request, context: Evaluators.context(), targets: rule.targets)
    }

    private class EvaluatorRequest: EvaluatorEventRequest {
        let key: EvaluatorKey
        let workspace: Workspace
        let user: HackleUser
        let event: UserEvent

        init(key: EvaluatorKey, workspace: Workspace, user: HackleUser, event: UserEvent) {
            self.key = key
            self.workspace = workspace
            self.user = user
            self.event = event
        }

        static func of(workspace: Workspace, event: UserEvent, inAppMessage: InAppMessage) -> EvaluatorRequest {
            EvaluatorRequest(
                key: EvaluatorKey(type: .inAppMessage, id: inAppMessage.id),
                workspace: workspace,
                user: event.user,
                event: event
            )
        }
    }
}
