import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultEvaluationFlowFactorySpecs: QuickSpec {
    override func spec() {
        var evaluationContext: EvaluationContext!
        var sut: DefaultEvaluationFlowFactory!

        beforeEach {
            evaluationContext = EvaluationContext()
            evaluationContext.register(DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()))
            evaluationContext.register(DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()))
            evaluationContext.initialize(
                evaluator: MockEvaluator(),
                manualOverrideStorage: DelegatingManualOverrideStorage(storages: []),
                clock: SystemClock.shared
            )
            sut = DefaultEvaluationFlowFactory(context: evaluationContext)
        }

        describe("flow") {

            it("AB_TEST") {
                sut.getExperimentFlow(experimentType: .abTest)
                    .isDecisionWith(OverrideEvaluator.self)!
                    .isDecisionWith(IdentifierEvaluator.self)!
                    .isDecisionWith(ContainerEvaluator.self)!
                    .isDecisionWith(ExperimentTargetEvaluator.self)!
                    .isDecisionWith(DraftExperimentEvaluator.self)!
                    .isDecisionWith(PausedExperimentEvaluator.self)!
                    .isDecisionWith(CompletedExperimentEvaluator.self)!
                    .isDecisionWith(TrafficAllocateEvaluator.self)!
                    .isEnd()
            }

            it("FEATURE_FLAG") {
                sut.getExperimentFlow(experimentType: .featureFlag)
                    .isDecisionWith(DraftExperimentEvaluator.self)!
                    .isDecisionWith(PausedExperimentEvaluator.self)!
                    .isDecisionWith(CompletedExperimentEvaluator.self)!
                    .isDecisionWith(OverrideEvaluator.self)!
                    .isDecisionWith(IdentifierEvaluator.self)!
                    .isDecisionWith(TargetRuleEvaluator.self)!
                    .isDecisionWith(DefaultRuleEvaluator.self)!
                    .isEnd()
            }

            it("IN_APP_MESSAGE") {
                sut.getInAppMessageFlow()
                    .isDecisionWith(PlatformInAppMessageEligibilityFlowEvaluator.self)!
                    .isDecisionWith(OverrideInAppMessageEligibilityFlowEvaluator.self)!
                    .isDecisionWith(DraftInAppMessageEligibilityFlowEvaluator.self)!
                    .isDecisionWith(PausedInAppMessageEligibilityFlowEvaluator.self)!
                    .isDecisionWith(PeriodInAppMessageEligibilityFlowEvaluator.self)!
                    .isDecisionWith(TargetInAppMessageEligibilityFlowEvaluator.self)!
                    .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                    .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                    .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                    .isEnd()
            }
        }
    }
}
