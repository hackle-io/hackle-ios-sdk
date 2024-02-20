//
//  EvaluationContext.swift
//  Hackle
//
//  Created by yong on 2023/06/01.
//

import Foundation


class EvaluationContext {

    static let shared = EvaluationContext()

    private var instances = [Any]()

    func get<T>(_ type: T.Type) -> T? {
        instances.first { instance in
            instance is T
        } as? T
    }

    func register(_ instance: Any) {
        instances.append(instance)
    }

    func initialize(evaluator: Evaluator, manualOverrideStorage: ManualOverrideStorage) {

        let bucketer = DefaultBucketer()
        let targetMatcher = DefaultTargetMatcher(conditionMatcherFactory: DefaultConditionMatcherFactory(evaluator: evaluator))
        let actionResolver = DefaultActionResolver(bucketer: bucketer)
        let overrideResolver = DefaultOverrideResolver(manualOverrideStorage: manualOverrideStorage, targetMatcher: targetMatcher, actionResolver: actionResolver)
        let containerResolver = DefaultContainerResolver(bucketer: bucketer)
        let experimentTargetDeterminer = DefaultExperimentTargetDeterminer(targetMatcher: targetMatcher)
        let experimentTargetRuleDeterminer = DefaultExperimentTargetRuleDeterminer(targetMatcher: targetMatcher)
        let remoteConfigTargetRuleDeterminer = DefaultRemoteConfigTargetRuleDeterminer(matcher: DefaultRemoteConfigTargetRuleMatcher(targetMatcher: targetMatcher, buckter: bucketer))
        let inAppMessageResolver = DefaultInAppMessageResolver(evaluator: evaluator)
        let inAppMessageUserOverrideMatcher = InAppMessageUserOverrideMatcher()
        let inAppMessageDoNotOpenMatcher = InAppMessageHiddenMatcher(storage: get(InAppMessageHiddenStorage.self)!)
        let inAppMessageTargetMatcher = InAppMessageTargetMatcher(targetMatcher: targetMatcher)

        register(bucketer)
        register(targetMatcher)
        register(actionResolver)
        register(overrideResolver)
        register(containerResolver)
        register(experimentTargetDeterminer)
        register(experimentTargetRuleDeterminer)
        register(remoteConfigTargetRuleDeterminer)
        register(inAppMessageResolver)
        register(inAppMessageUserOverrideMatcher)
        register(inAppMessageDoNotOpenMatcher)
        register(inAppMessageTargetMatcher)
    }
}
