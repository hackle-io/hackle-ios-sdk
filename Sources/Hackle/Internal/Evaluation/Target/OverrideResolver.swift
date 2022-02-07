//
//  OverrideResolver.swift
//  Hackle
//
//  Created by yong on 2022/01/28.
//

import Foundation


protocol OverrideResolver {
    func resolveOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Variation?
}

class DefaultOverrideResolver: OverrideResolver {

    private let targetMatcher: TargetMatcher
    private let actionResolver: ActionResolver

    init(targetMatcher: TargetMatcher, actionResolver: ActionResolver) {
        self.targetMatcher = targetMatcher
        self.actionResolver = actionResolver
    }

    func resolveOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Variation? {
        if let overriddenVariationId = experiment.userOverrides[user.id] {
            return experiment.getVariationOrNil(variationId: overriddenVariationId)
        }
        guard let overriddenRule = try experiment.segmentOverrides.first(
            where: { it in try targetMatcher.matches(target: it.target, workspace: workspace, user: user) }
        ) else {
            return nil
        }
        return try actionResolver.resolveOrNil(action: overriddenRule.action, workspace: workspace, experiment: experiment, user: user)
    }
}
