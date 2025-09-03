import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultExperimentFlowFactorySpecs: QuickSpec {
    override func spec() {
        var evaluationContext: EvaluationContext!
        var sut: DefaultExperimentFlowFactory!

        beforeEach {
            evaluationContext = EvaluationContext()
            evaluationContext.register(DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()))
            evaluationContext.register(DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()))
            evaluationContext.initialize(
                evaluator: MockEvaluator(),
                manualOverrideStorage: DelegatingManualOverrideStorage(storages: []),
                clock: SystemClock.shared
            )
            sut = DefaultExperimentFlowFactory(context: evaluationContext)
        }

        describe("flow") {

            it("AB_TEST") {
                sut.get(experimentType: .abTest)
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
                sut.get(experimentType: .featureFlag)
                    .isDecisionWith(DraftExperimentEvaluator.self)!
                    .isDecisionWith(PausedExperimentEvaluator.self)!
                    .isDecisionWith(CompletedExperimentEvaluator.self)!
                    .isDecisionWith(OverrideEvaluator.self)!
                    .isDecisionWith(IdentifierEvaluator.self)!
                    .isDecisionWith(TargetRuleEvaluator.self)!
                    .isDecisionWith(DefaultRuleEvaluator.self)!
                    .isEnd()
            }
        }
    }
}
