import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultExperimentFlowFactorySpecs: QuickSpec {
    override class func spec() {
        var sut: DefaultExperimentLocalEvaluationFlowFactory!

        beforeEach {
            sut = DefaultExperimentLocalEvaluationFlowFactory(
                targetMatcher: DefaultTargetMatcher(conditionMatcherFactory: DefaultConditionMatcherFactory(evaluator: DelegatingEvaluator(evaluatorFactory: EvaluatorFactory()), clock: SystemClock.shared)),
                bucketer: DefaultBucketer(),
                overrideStorage: DelegatingManualOverrideStorage(storages: [])
            )
        }

        describe("flow") {

            it("AB_TEST") {
                sut.flow(experimentType: .abTest)
                    .isDecisionWith(OverrideExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(IdentifierExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(ContainerExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(TargetExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(DraftExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(PausedExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(CompletedExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(TrafficAllocateExperimentLocalFlowEvaluator.self)!
                    .isEnd()
            }

            it("FEATURE_FLAG") {
                sut.flow(experimentType: .featureFlag)
                    .isDecisionWith(DraftExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(PausedExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(CompletedExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(OverrideExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(IdentifierExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(TargetRuleExperimentLocalFlowEvaluator.self)!
                    .isDecisionWith(DefaultRuleExperimentLocalFlowEvaluator.self)!
                    .isEnd()
            }
        }
    }
}
