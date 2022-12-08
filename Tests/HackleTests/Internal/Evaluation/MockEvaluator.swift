import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockEvaluator: Mock, Evaluator {
    lazy var evaluateExperimentMock = MockFunction(self, evaluateExperiment)

    func evaluateExperiment(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Evaluation {
        call(evaluateExperimentMock, args: (workspace, experiment, user, defaultVariationKey))
    }

    lazy var evaluateRemoteConfigMock = MockFunction(self, evaluateRemoteConfig)

    func evaluateRemoteConfig(workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigEvaluation {
        call(evaluateRemoteConfigMock, args: (workspace, parameter, user, defaultValue))
    }
}