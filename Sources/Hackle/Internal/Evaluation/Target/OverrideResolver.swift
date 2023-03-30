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

    private let manualOverrideStorage: ManualOverrideStorage
    private let targetMatcher: TargetMatcher
    private let actionResolver: ActionResolver

    init(manualOverrideStorage: ManualOverrideStorage, targetMatcher: TargetMatcher, actionResolver: ActionResolver) {
        self.manualOverrideStorage = manualOverrideStorage
        self.targetMatcher = targetMatcher
        self.actionResolver = actionResolver
    }

    func resolveOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Variation? {

        if let overriddenVariation = resolveManualOverrideOrNil(experiment: experiment, user: user) {
            return overriddenVariation
        }

        if let overriddenVariation = resolveUserOverrideOrNil(experiment: experiment, user: user) {
            return overriddenVariation
        }
        return try resolveSegmentOverrideOrNil(workspace: workspace, experiment: experiment, user: user)
    }

    private func resolveManualOverrideOrNil(experiment: Experiment, user: HackleUser) -> Variation? {
        manualOverrideStorage.get(experiment: experiment, user: user)
    }

    private func resolveUserOverrideOrNil(experiment: Experiment, user: HackleUser) -> Variation? {
        guard let identifier = user.identifiers[experiment.identifierType] else {
            return nil
        }
        guard let overriddenVariationId = experiment.userOverrides[identifier] else {
            return nil
        }
        return experiment.getVariationOrNil(variationId: overriddenVariationId)
    }

    private func resolveSegmentOverrideOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Variation? {
        guard let overriddenRule = try experiment.segmentOverrides.first(
            where: { it in try targetMatcher.matches(target: it.target, workspace: workspace, user: user) }
        )
        else {
            return nil
        }
        return try actionResolver.resolveOrNil(action: overriddenRule.action, workspace: workspace, experiment: experiment, user: user)
    }
}
