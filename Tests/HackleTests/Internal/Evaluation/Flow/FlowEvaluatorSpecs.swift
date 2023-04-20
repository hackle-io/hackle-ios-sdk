import Foundation
import Quick
import Nimble
@testable import Hackle


class FlowEvaluatorSpecs: QuickSpec {
    override func spec() {

        let user = HackleUser.of(userId: "test_id")

        var nextFlow: MockEvaluationFlow!
        var evaluation: ExperimentEvaluation!
        var context: EvaluatorContext!

        beforeEach {
            evaluation = experimentEvaluation()
            nextFlow = MockEvaluationFlow()
            every(nextFlow.evaluateMock).returns(evaluation)
            context = Evaluators.context()
        }

        describe("OverrideEvaluator") {

            var overrideResolver: MockOverrideResolver!
            var sut: OverrideEvaluator!

            beforeEach {
                overrideResolver = MockOverrideResolver()
                sut = OverrideEvaluator(overrideResolver: overrideResolver)
            }

            it("AbTest 인 경우 override된 사용자인 경우 overriddenVariation, OVERRIDDEN 으로 평가한다") {
                // given
                let experiment = experiment(type: .abTest)
                let variation = experiment.variations.first
                every(overrideResolver.resolveOrNilMock).returns(variation)

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.OVERRIDDEN
                expect(actual.variationId) == variation?.id
            }

            it("FeatureFlag 인 경우override된 사용자인 경우 overriddenVariation, INDIVIDUAL_TARGET_MATCH 으로 평가한다") {
                // given
                let experiment = experiment(type: .featureFlag)
                let variation = experiment.variations.first
                every(overrideResolver.resolveOrNilMock).returns(variation)

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.INDIVIDUAL_TARGET_MATCH
                expect(actual.variationId) == variation?.id
            }

            it("override된 사용자가 아닌경우 다음 Flow로 평가한다") {
                // given
                let experiment = experiment(type: .abTest)
                every(overrideResolver.resolveOrNilMock).returns(nil)

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }
        }

        describe("DraftExperimentEvaluator") {
            it("DRAFT상태면 기본그룹으로 평가한다") {
                // given
                let experiment = experiment(type: .abTest, status: .draft)
                let variation = experiment.variations.first!

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try DraftExperimentEvaluator().evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.EXPERIMENT_DRAFT
                expect(actual.variationId) == variation.id
            }

            it("DRAFT상태가 아니면 다름 flow로 평가한다") {
                // given
                let experiment = experiment(type: .abTest, status: .running)
                let variation = experiment.variations.first!

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try DraftExperimentEvaluator().evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }
        }

        describe("PausedExperimentEvaluator") {

            it("AB 테스트가 PAUSED 상태면 기본그룹, EXPERIMENT_PAUSED으로 평가한다") {
                // given
                let experiment = experiment(type: .abTest, status: .paused)
                let variation = experiment.variations.first!

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try PausedExperimentEvaluator().evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.EXPERIMENT_PAUSED
                expect(actual.variationId) == variation.id
            }

            it("기능 플래그가 PAUSED 상태면 기본그룹, FEATURE_FLAG_INACTIVE 로 평가한다") {
                // given
                let experiment = experiment(type: .featureFlag, status: .paused)
                let variation = experiment.variations.first!

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try PausedExperimentEvaluator().evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.FEATURE_FLAG_INACTIVE
                expect(actual.variationKey) == "A"
            }

            it("PAUSED 상태가 아니면 다음 플로우 실행한다") {
                // given
                let experiment = experiment(type: .abTest, status: .running)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try PausedExperimentEvaluator().evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }
        }

        describe("CompletedExperimentEvaluator") {

            it("COMPLETED 상태면 위너 그룹 평가한다") {
                // given
                let experiment = experiment(status: .completed, winnerVariationId: 2)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try CompletedExperimentEvaluator().evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.EXPERIMENT_COMPLETED
                expect(actual.variationId) == 2
            }

            it("COMPLETED 상태지만 winner variation 이 없으면 에러") {
                // given
                let experiment = experiment(id: 42, status: .completed)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = expect(try CompletedExperimentEvaluator().evaluate(request: request, context: context, nextFlow: nextFlow))

                // then
                actual.to(throwError(HackleError.error("winner variation [42]")))
            }

            it("COMPLETED 상태가 아니면 다음 플로우를 실행한다") {
                // given
                let experiment = experiment(status: .running)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try CompletedExperimentEvaluator().evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual) == evaluation
            }
        }

        describe("ExperimentTargetEvaluator") {

            var experimentTargetDeterminer: MockExperimentTargetDeterminer!
            var sut: ExperimentTargetEvaluator!
            beforeEach {
                experimentTargetDeterminer = MockExperimentTargetDeterminer()
                sut = ExperimentTargetEvaluator(experimentTargetDeterminer: experimentTargetDeterminer)
            }

            it("abTest 타입이 아니면 예외 발생") {
                let experiment = experiment(id: 42, type: .featureFlag)
                let request = experimentRequest(experiment: experiment)
                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))
                    .to(throwError(HackleError.error("Experiment type must be abTest [42]")))
            }

            it("사용자가 실험 참여 대상이면 다음 플로우를 실행한다") {
                // given
                let experiment = experiment(id: 42, type: .abTest, status: .running)
                every(experimentTargetDeterminer.isUserInExperimentTargetMock).returns(true)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual) == evaluation
                verify(exactly: 1) {
                    nextFlow.evaluateMock
                }
            }

            it("사용자가 실험 참여 대상이 아니면 기본그룹으로 평가한다") {
                // given
                let experiment = experiment(id: 42, type: .abTest, status: .running)
                every(experimentTargetDeterminer.isUserInExperimentTargetMock).returns(false)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.NOT_IN_EXPERIMENT_TARGET
                expect(actual.variationKey) == "A"
            }
        }

        describe("TrafficAllocateEvaluator") {

            var actionResolver: MockActionResolver!
            var sut: TrafficAllocateEvaluator!

            beforeEach {
                actionResolver = MockActionResolver()
                sut = TrafficAllocateEvaluator(actionResolver: actionResolver)
            }

            it("실행중이 아니면 예외 발생") {
                let experiment = experiment(id: 42, type: .abTest, status: .draft)
                let request = experimentRequest(experiment: experiment)
                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))
                    .to(throwError(HackleError.error("Experiment status must be running [42]")))
            }

            it("abTest 타입이 아니면 예외 발생") {
                let experiment = experiment(id: 42, type: .featureFlag, status: .running)
                let request = experimentRequest(experiment: experiment)
                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))
                    .to(throwError(HackleError.error("Experiment type must be abTest [42]")))
            }

            it("기본룰에 해당하는 Variation이 없으면 기본그룹으로 평가한다") {
                // given
                let experiment = experiment(type: .abTest, status: .running)
                let request = experimentRequest(experiment: experiment)
                every(actionResolver.resolveOrNilMock).returns(nil)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.TRAFFIC_NOT_ALLOCATED
                expect(actual.variationKey) == "A"
            }

            it("할당된 Variation이 드랍 되었으면 기본그룹으로 평간한다") {
                let experiment = experiment(type: .abTest, status: .running, variations: [
                    VariationEntity(id: 1, key: "A", isDropped: false, parameterConfigurationId: nil),
                    VariationEntity(id: 2, key: "B", isDropped: true, parameterConfigurationId: nil)
                ])
                let request = experimentRequest(experiment: experiment)
                every(actionResolver.resolveOrNilMock).returns(experiment.getVariationOrNil(variationKey: "B"))

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.VARIATION_DROPPED
                expect(actual.variationKey) == "A"
            }

            it("할당된 Variation 으로 평가한다") {
                // given
                let experiment = experiment(type: .abTest, status: .running)
                every(actionResolver.resolveOrNilMock).returns(experiment.variations.first)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.TRAFFIC_ALLOCATED
                expect(actual.variationKey) == "A"
            }
        }

        describe("TargetRuleEvaluator") {

            var targetRuleDeterminer: MockExperimentTargetRuleDeterminer!
            var actionResolver: MockActionResolver!
            var sut: TargetRuleEvaluator!

            beforeEach {
                targetRuleDeterminer = MockExperimentTargetRuleDeterminer()
                actionResolver = MockActionResolver()
                sut = TargetRuleEvaluator(targetRuleDeterminer: targetRuleDeterminer, actionResolver: actionResolver)
            }

            it("실행중이 아니면 예외 발생") {
                let experiment = experiment(id: 42, type: .featureFlag, status: .draft)
                let request = experimentRequest(experiment: experiment)
                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))
                    .to(throwError(HackleError.error("Experiment status must be running [42]")))
            }

            it("featureFlag 타입이 아니면 예외 발생") {
                let experiment = experiment(id: 42, type: .abTest, status: .running)
                let request = experimentRequest(experiment: experiment)
                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))
                    .to(throwError(HackleError.error("Experiment type must be featureFlag [42]")))
            }

            it("identifierType에 해당하는 식별자가 없으면 다음 플로우를 실행한다") {
                // given
                let experiment = experiment(type: .featureFlag, identifierType: "custom", status: .running)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual) == evaluation
            }

            it("타겟룰에 해당하지 않으면 다음 플로우를 실행한다") {
                // given
                let experiment = experiment(id: 42, type: .featureFlag, status: .running)
                every(targetRuleDeterminer.determineTargetRuleOrNilMock).returns(nil)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual) == evaluation
            }

            it("타겟룰에 매치했지만 Action에 해당하는 Variation이 결정되지 않으면 예외 발생") {
                // given
                let experiment = experiment(id: 42, type: .featureFlag, status: .running)

                let targetRule = MockTargetRule()
                every(targetRuleDeterminer.determineTargetRuleOrNilMock).returns(targetRule)

                every(actionResolver.resolveOrNilMock).returns(nil)

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))

                // then
                actual.to(throwError(HackleError.error("FeatureFlag must decide the Variation [42]")))
            }

            it("일치하는 타겟룰이 있는 경우 해당 룰에 해당하는 Variation 으로 결정한다") {
                // given
                let experiment = experiment(id: 42, type: .featureFlag, status: .running)

                let targetRule = MockTargetRule()
                every(targetRuleDeterminer.determineTargetRuleOrNilMock).returns(targetRule)

                let variation = experiment.variations.first!
                every(actionResolver.resolveOrNilMock).returns(variation)

                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.TARGET_RULE_MATCH
                expect(actual.variationId) == variation.id
            }
        }

        describe("DefaultRuleEvaluator") {

            var actionResolver: MockActionResolver!
            var sut: DefaultRuleEvaluator!

            beforeEach {
                actionResolver = MockActionResolver()
                sut = DefaultRuleEvaluator(actionResolver: actionResolver)
            }

            it("실행중이 아니면 예외 발생") {
                let experiment = experiment(id: 42, type: .featureFlag, status: .draft)
                let request = experimentRequest(experiment: experiment)
                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))
                    .to(throwError(HackleError.error("Experiment status must be running [42]")))
            }

            it("featureFlag 타입이 아니면 예외 발생") {
                let experiment = experiment(id: 42, type: .abTest, status: .running)
                let request = experimentRequest(experiment: experiment)
                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))
                    .to(throwError(HackleError.error("Experiment type must be featureFlag [42]")))
            }

            it("identifierType에 해당하는 식별자가 없으면 defaultVariation을 리턴한다") {
                // given
                let experiment = experiment(id: 42, type: .featureFlag, identifierType: "custom", status: .running)
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.DEFAULT_RULE
                expect(actual.variationKey) == "A"
            }

            it("기본 룰에 해당하는 Variation을 결정하지 못하면 예외 발생") {
                // given
                let experiment = experiment(id: 42, type: .featureFlag, status: .running)
                let request = experimentRequest(experiment: experiment)
                every(actionResolver.resolveOrNilMock).returns(nil)

                expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))
                    .to(throwError(HackleError.error("FeatureFlag must decide the Variation [42]")))
            }

            it("기본 룰에 해당하는 Variation 으로 평가한다") {
                // given
                let experiment = experiment(id: 42, type: .featureFlag, status: .running)
                let request = experimentRequest(experiment: experiment)

                let variation = experiment.variations.first!
                every(actionResolver.resolveOrNilMock).returns(variation)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.DEFAULT_RULE
                expect(actual.variationId) == variation.id
            }
        }

        describe("ContainerEvaluator") {

            var containerResolver: MockContainerResolver!
            var sut: ContainerEvaluator!

            beforeEach {
                containerResolver = MockContainerResolver()
                sut = ContainerEvaluator(containerResolver: containerResolver)
            }

            it("Experiment 가 Container 를 가지고 있지 않는 경우 nextFlow 로 평가한다") {
                // given
                let experiment = experiment()
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual) == evaluation
            }


            it("containerId 로 Container 를 찾을 수 없으면 예외 발생") {
                // given
                let experiment = experiment(containerId: 42)

                let workspace = MockWorkspace()
                every(workspace.getContainerOrNilMock).returns(nil)

                let request = experimentRequest(workspace: workspace, experiment: experiment)

                // when
                let actual = expect(try sut.evaluate(request: request, context: context, nextFlow: nextFlow))

                // then
                actual.to(throwError(HackleError.error("Container[42]")))
            }


            it("ContainerGroup 에 속해있으면 nextFlow 로 평가한다") {
                // given
                let experiment = experiment(containerId: 42)

                let workspace = MockWorkspace()
                let container = MockContainer(bucketId: 320)
                every(workspace.getContainerOrNilMock).returns(container)

                every(containerResolver.isUserInContainerGroupMock).returns(true)

                let request = experimentRequest(workspace: workspace, experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual) == evaluation
            }

            it("ContainerGroup 에 속해있지 않으면 NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT") {
                // given
                let experiment = experiment(type: .abTest, containerId: 22)

                let workspace = MockWorkspace()
                let container = MockContainer(bucketId: 320)
                every(workspace.getContainerOrNilMock).returns(container)
                every(containerResolver.isUserInContainerGroupMock).returns(false)

                let request = experimentRequest(workspace: workspace, experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT
                expect(actual.variationKey) == "A"
            }
        }

        describe("IdentifierEvaluator") {

            var sut: IdentifierEvaluator!

            beforeEach {
                sut = IdentifierEvaluator()
            }

            it("identifierType 에 해당하는 identifier 가 있으면 nextFlow") {
                // given
                let experiment = experiment()
                let request = experimentRequest(experiment: experiment)

                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual) == evaluation
            }

            it("identifierType 에 해당하는 identifier 가 없으면 IDENTIFIER_NOT_FOUND") {
                // given
                let experiment = experiment(identifierType: "custom")
                let request = experimentRequest(experiment: experiment)


                // when
                let actual = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                // then
                expect(actual.reason) == DecisionReason.IDENTIFIER_NOT_FOUND
                expect(actual.variationKey) == "A"
            }
        }
    }
}
