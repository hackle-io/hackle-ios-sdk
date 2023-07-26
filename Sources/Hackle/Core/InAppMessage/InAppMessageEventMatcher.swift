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
    private let frequencyCapDeterminer: InAppMessageEventTriggerDeterminer

    init(ruleDeterminer: InAppMessageEventTriggerDeterminer, frequencyCapDeterminer: InAppMessageEventTriggerDeterminer) {
        self.ruleDeterminer = ruleDeterminer
        self.frequencyCapDeterminer = frequencyCapDeterminer
    }

    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvent) throws -> Bool {
        guard let trackEvent = event as? UserEvents.Track else {
            return false
        }

        guard try ruleDeterminer.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: trackEvent) else {
            return false
        }

        return try frequencyCapDeterminer.isTriggerTarget(workspace: workspace, inAppMessage: inAppMessage, event: trackEvent)
    }
}
