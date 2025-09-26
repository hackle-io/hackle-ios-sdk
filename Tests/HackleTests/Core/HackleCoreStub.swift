//
//  MockHackleCore.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
import MockingKit
@testable import Hackle

class HackleCoreStub: HackleCore {

    var tracked = [(Event, HackleUser, Date)]()

    func initialize(completion: @escaping () -> ()) {

    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision {
        fatalError("experiment(experimentKey:user:defaultVariationKey:) has not been implemented")
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        fatalError("experiments(user:) has not been implemented")
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        fatalError("featureFlag(featureKey:user:) has not been implemented")
    }

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        fatalError("featureFlags(user:) has not been implemented")
    }

    func track(event: Event, user: HackleUser) {
        tracked.append((event, user, Date()))
    }

    func track(event: Event, user: HackleUser, timestamp: Date) {
        tracked.append((event, user, timestamp))
    }

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        fatalError("remoteConfig(parameterKey:user:defaultValue:) has not been implemented")
    }

    var inAppMessageDecisions: [InAppMessageDecision] = [] {
        didSet {
            inAppMessageCount = 0
        }
    }
    var inAppMessageCount = 0

    func inAppMessage(inAppMessageKey: Int64, user: HackleUser) throws -> InAppMessageDecision {
        let decision = inAppMessageDecisions[inAppMessageCount]
        inAppMessageCount += 1
        return decision
    }

    var evaluations: [InAppMessageEvaluatorEvaluation] = [] {
        didSet {
            evaluationCount = 0
        }
    }
    var evaluationCount = 0

    func inAppMessage<Evaluation>(request: InAppMessageEvaluatorRequest, context: EvaluatorContext, evaluator: InAppMessageEvaluator) throws -> Evaluation where Evaluation: InAppMessageEvaluatorEvaluation {
        let evaluation = evaluations[evaluationCount]
        evaluationCount += 1
        return evaluation as! Evaluation
    }
}
