import Foundation
import MockingKit
@testable import Hackle

class MockHackleCore: Mock, HackleCore {

    lazy var experimentMock = MockFunction.throwable(self, experiment)

    func experiment(experimentKey: Experiment.Key, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Decision {
        try call(experimentMock, args: (experimentKey, user, defaultVariationKey))
    }

    lazy var experimentsMock = MockFunction.throwable(self, experiments)

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        try call(experimentsMock, args: user)
    }

    lazy var featureFlagMock = MockFunction.throwable(self, featureFlag)

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        try call(featureFlagMock, args: (featureKey, user))
    }

    lazy var featureFlagsMock = MockFunction.throwable(self, featureFlags)

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        try call(featureFlagsMock, args: user)
    }

    func track(event: Event, user: HackleUser) {
        track(event: event, user: user, timestamp: Date())
    }

    lazy var trackMock = MockFunction(self, track as (Event, HackleUser, Date) -> ())

    func track(event: Event, user: HackleUser, timestamp: Date) {
        call(trackMock, args: (event, user, timestamp))
    }

    lazy var remoteConfigMock = MockFunction(self, remoteConfig)

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        call(remoteConfigMock, args: (parameterKey, user, defaultValue))
    }

    lazy var inAppMessageMock = MockFunction.throwable(self, _inAppMessage)

    func inAppMessage<Evaluation>(request: InAppMessageEvaluatorRequest, context: EvaluatorContext, evaluator: InAppMessageEvaluator) throws -> Evaluation where Evaluation: InAppMessageEvaluatorEvaluation {
        return try _inAppMessage(request: request, context: context, evaluator: evaluator) as! Evaluation
    }

    private func _inAppMessage(request: InAppMessageEvaluatorRequest, context: EvaluatorContext, evaluator: InAppMessageEvaluator) throws -> EvaluatorEvaluation {
        return try call(inAppMessageMock, args: (request, context, evaluator))
    }
}
