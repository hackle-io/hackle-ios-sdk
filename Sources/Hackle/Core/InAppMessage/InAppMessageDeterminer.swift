//
//  InAppMessageTriggerDeterminer.swift
//  Hackle
//
//  Created by yong on 2023/06/07.
//

import Foundation

protocol InAppMessageDeterminer {
    func determineOrNull(event: UserEvent) throws -> InAppMessagePresentationContext?
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

    func determineOrNull(event: UserEvent) throws -> InAppMessagePresentationContext? {

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

    private func context(inAppMessage: InAppMessage, event: UserEvent) -> InAppMessagePresentationContext? {
        let decision = core.tryInAppMessage(inAppMessageKey: inAppMessage.key, user: event.user)
        Log.debug("InAppMessage [\(inAppMessage.key)]: \(decision.reason)")
        
        guard let inAppMessage = decision.inAppMessage, let message = decision.message else {
            return nil
        }

        let properties = PropertiesBuilder()
            .add(decision.properties)
            .add("decision_reason", decision.reason)
            .add("trigger_event_insert_id", event.insertId)
            .build()

        return InAppMessagePresentationContext(
            inAppMessage: inAppMessage,
            message: message,
            user: event.user,
            properties: properties,
            decisionReasion: decision.reason
        )
    }
}
