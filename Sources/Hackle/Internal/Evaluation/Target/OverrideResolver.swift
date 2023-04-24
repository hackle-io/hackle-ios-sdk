//
//  OverrideResolver.swift
//  Hackle
//
//  Created by yong on 2022/01/28.
//

import Foundation


protocol OverrideResolver {
    func resolveOrNil(request: ExperimentRequest, context: EvaluatorContext) throws -> Variation?
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

    func resolveOrNil(request: ExperimentRequest, context: EvaluatorContext) throws -> Variation? {

        if let overriddenVariation = resolveManualOverrideOrNil(request: request) {
            return overriddenVariation
        }

        if let overriddenVariation = resolveUserOverrideOrNil(request: request) {
            return overriddenVariation
        }
        return try resolveSegmentOverrideOrNil(request: request, context: context)
    }

    private func resolveManualOverrideOrNil(request: ExperimentRequest) -> Variation? {
        manualOverrideStorage.get(experiment: request.experiment, user: request.user)
    }

    private func resolveUserOverrideOrNil(request: ExperimentRequest) -> Variation? {
        let experiment = request.experiment
        guard let identifier = request.user.identifiers[experiment.identifierType] else {
            return nil
        }
        guard let overriddenVariationId = experiment.userOverrides[identifier] else {
            return nil
        }
        return experiment.getVariationOrNil(variationId: overriddenVariationId)
    }

    private func resolveSegmentOverrideOrNil(request: ExperimentRequest, context: EvaluatorContext) throws -> Variation? {
        guard let overriddenRule = try request.experiment.segmentOverrides.first(where: { it in try targetMatcher.matches(request: request, context: context, target: it.target) }) else {
            return nil
        }
        return try actionResolver.resolveOrNil(request: request, action: overriddenRule.action)
    }
}
