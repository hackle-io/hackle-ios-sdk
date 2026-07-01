//
//  OverrideResolver.swift
//  Hackle
//
//  Created by yong on 2022/01/28.
//

import Foundation


protocol OverrideResolver {
    func resolveOrNil(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> Variation?
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

    func resolveOrNil(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> Variation? {

        if let overriddenVariation = resolveManualOverrideOrNil(request: request) {
            return overriddenVariation
        }

        if let overriddenVariation = resolveUserOverrideOrNil(request: request) {
            return overriddenVariation
        }
        return try resolveSegmentOverrideOrNil(request: request, context: context)
    }

    private func resolveManualOverrideOrNil(request: ExperimentLocalEvaluateRequest) -> Variation? {
        manualOverrideStorage.get(experiment: request.experimentConfig, user: request.user)
    }

    private func resolveUserOverrideOrNil(request: ExperimentLocalEvaluateRequest) -> Variation? {
        let experiment = request.experiment
        guard let identifier = request.user.identifiers[experiment.identifierType] else {
            return nil
        }
        guard let overriddenVariationId = experiment.userOverrides[identifier] else {
            return nil
        }
        return experiment.getVariationOrNil(variationId: overriddenVariationId)
    }

    private func resolveSegmentOverrideOrNil(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> Variation? {
        guard let overriddenRule = try request.experiment.segmentOverrides.first(where: { it in try targetMatcher.matches(request: request, context: context, target: it.target) }) else {
            return nil
        }
        return try actionResolver.resolveOrNil(request: request, action: overriddenRule.action)
    }
}
