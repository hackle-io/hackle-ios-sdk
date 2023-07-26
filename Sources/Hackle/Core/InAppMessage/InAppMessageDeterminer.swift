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

        return InAppMessageContext(
            inAppMessage: inAppMessage,
            message: message,
            user: event.user,
            properties: properties
        )
    }
}
