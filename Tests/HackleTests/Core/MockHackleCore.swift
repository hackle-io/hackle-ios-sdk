import Foundation
import Mockery
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

    lazy var inAppMessageMock = MockFunction(self, inAppMessage)

    func inAppMessage(inAppMessageKey: Int64, user: HackleUser) throws -> InAppMessageDecision {
        call(inAppMessageMock, args: (inAppMessageKey, user))
    }

    lazy var evaluateMock: MockFunction<(any EvaluatorRequest, EvaluatorContext, any ContextualEvaluator), any EvaluatorEvaluation> = MockFunction(self, _evaluateAny)

    func evaluate<Evaluator: ContextualEvaluator>(request: Evaluator.Request, context: EvaluatorContext, evaluator: Evaluator) throws -> Evaluator.Evaluation {
        return _evaluateAny(request: request, context: context, evaluator: evaluator) as! Evaluator.Evaluation
    }

    private func _evaluateAny(request: any EvaluatorRequest, context: EvaluatorContext, evaluator: any ContextualEvaluator) -> any EvaluatorEvaluation {
        return call(evaluateMock, args: (request, context, evaluator))
    }
}
