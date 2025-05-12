//
//  InAppMessageEventMatcher.swift
//  Hackle
//
//  Created by yong on 2023/07/19.
//

import Foundation


protocol InAppMessageEventMatcher {
    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvent) throws -> Bool
}

class DefaultInAppMessageEventMatcher: InAppMessageEventMatcher {

    private let ruleDeterminer: InAppMessageEventTriggerDeterminer

    init(ruleDeterminer: InAppMessageEventTriggerDeterminer) {
        self.ruleDeterminer = ruleDeterminer
    }

    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvent) throws -> Bool {
        guard let trackEvent = event as? UserEvents.Track else {
            return false
        }

        return try ruleDeterminer.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: trackEvent)
    }
}
