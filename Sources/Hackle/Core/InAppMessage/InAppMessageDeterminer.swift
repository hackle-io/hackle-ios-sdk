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
        // TODO: Not yet implemented
        return nil
    }
}
