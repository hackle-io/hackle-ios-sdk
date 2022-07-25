import Foundation
import Quick
import Nimble
@testable import Hackle


class FlowEvaluatorSpecs: QuickSpec {
    override func spec() {

        let user = HackleUser.of(userId: "test_id")

        describe("OverrideEvaluator") {

            var overrideResolver: MockOverrideResolver!
            var sut: OverrideEvaluator!

            beforeEach {
                overrideResolver = MockOverrideResolver()
                sut = OverrideEvaluator(overrideResolver: overrideResolver)
            }

            it("AbTest 인 경우 override된 사용자인 경우 overriddenVariation, OVERRIDDEN 으로 평가한다") {
                // given
                let variation = MockVariation(id: 320, key: "B")
                let experiment = MockExperiment(type: .abTest)
                every(overrideResolver.resolveOrNilMock).returns(variation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "C", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.OVERRIDDEN)))
            }

            it("FeatureFlag 인 경우override된 사용자인 경우 overriddenVariation, INDIVIDUAL_TARGET_MATCH 으로 평가한다") {
                // given
                let variation = MockVariation(id: 320, key: "B")
                let experiment = MockExperiment(type: .featureFlag)
                every(overrideResolver.resolveOrNilMock).returns(variation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "C", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.INDIVIDUAL_TARGET_MATCH)))
            }

            it("override된 사용자가 아닌경우 다음 Flow로 평가한다") {
                // given
                let experiment = MockExperiment(type: .abTest)
                every(overrideResolver.resolveOrNilMock).returns(nil)

                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "C", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }
        }

        describe("DraftExperimentEvaluator") {
            it("DRAFT상태면 기본그룹으로 평가한다") {
                // given
                let experiment = MockExperiment(status: .draft)
                let variation = MockVariation(id: 42, key: "J", isDropped: false)
                every(experiment.getVariationByKeyOrNilMock).returns(variation)

                // when
                let actual = try DraftExperimentEvaluator().evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "J", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "J", reason: DecisionReason.EXPERIMENT_DRAFT)))
            }

            it("DRAFT상태가 아니면 다름 flow로 평가한다") {
                // given
                let experiment = MockExperiment(status: .running)
                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try DraftExperimentEvaluator().evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "D", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
                verify(exactly: 1) {
                    nextFlow.evaluateMock
                }
            }
        }

        describe("PausedExperimentEvaluator") {

            it("AB 테스트가 PAUSED 상태면 기본그룹, EXPERIMENT_PAUSED으로 평가한다") {
                // given
                let experiment = MockExperiment(type: .abTest, status: .paused)
                let variation = MockVariation(id: 42, key: "B", isDropped: false)
                every(experiment.getVariationByKeyOrNilMock).returns(variation)

                // when
                let actual = try PausedExperimentEvaluator().evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "B", reason: DecisionReason.EXPERIMENT_PAUSED)))
            }

            it("기능 플래그가 PAUSED 상태면 기본그룹, FEATURE_FLAG_INACTIVE 로 평가한다") {
                // given
                let experiment = MockExperiment(type: .featureFlag, status: .paused)
                let variation = MockVariation(id: 42, key: "A", isDropped: false)
                every(experiment.getVariationByKeyOrNilMock).returns(variation)

                // when
                let actual = try PausedExperimentEvaluator().evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "A", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "A", reason: DecisionReason.FEATURE_FLAG_INACTIVE)))
            }
        }

        describe("CompletedExperimentEvaluator") {

            it("COMPLETED 상태면 위너 그룹 평가한다") {
                // given
                let variation = MockVariation(id: 320, key: "E")
                let experiment = MockExperiment(status: .completed, winnerVariation: variation)

                // when
                let actual = try CompletedExperimentEvaluator().evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 320, variationKey: "E", reason: DecisionReason.EXPERIMENT_COMPLETED)))
            }

            it("COMPLETED 상태가 아니면 다음 플로우를 실행한다") {
                // given
                let experiment = MockExperiment(status: .running)
                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try CompletedExperimentEvaluator().evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "B", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
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
                expect(try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(id: 42, type: .featureFlag), user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow()))
                    .to(throwError(HackleError.error("Experiment type must be abTest [42]")))
            }

            it("사용자가 실험 참여 대상이면 다음 플로우를 실행한다") {
                // given
                let experiment = MockExperiment(id: 42, type: .abTest, status: .running)
                every(experimentTargetDeterminer.isUserInExperimentTargetMock).returns(true)

                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
                verify(exactly: 1) {
                    nextFlow.evaluateMock
                }
            }

            it("사용자가 실험 참여 대상이 아니면 기본그룹으로 평가한다") {
                // given
                let experiment = MockExperiment(id: 42, type: .abTest, status: .running)
                let variation = MockVariation(id: 42, key: "E")
                every(experiment.getVariationByKeyOrNilMock).returns(variation)
                every(experimentTargetDeterminer.isUserInExperimentTargetMock).returns(false)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "E", reason: DecisionReason.NOT_IN_EXPERIMENT_TARGET)))
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
                expect(try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(id: 42, status: .draft), user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow()))
                    .to(throwError(HackleError.error("Experiment status must be running [42]")))
            }

            it("abTest 타입이 아니면 예외 발생") {
                expect(try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(id: 42, type: .featureFlag), user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow()))
                    .to(throwError(HackleError.error("Experiment type must be abTest [42]")))
            }

            it("기본룰에 해당하는 Variation이 없으면 기본그룹으로 평가한다") {
                // given
                let experiment = MockExperiment(type: .abTest, status: .running)
                let variation = MockVariation(id: 42, key: "G")
                every(experiment.getVariationByKeyOrNilMock).returns(variation)

                every(actionResolver.resolveOrNilMock).returns(nil)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "G", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "G", reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)))
            }

            it("할당된 Variation이 드랍 되었으면 기본그룹으로 평간한다") {
                // given
                let experiment = MockExperiment(type: .abTest)
                let variation = MockVariation(id: 42, key: "G")
                every(experiment.getVariationByKeyOrNilMock).returns(variation)

                let resolvedVariation = MockVariation(id: 320, key: "B", isDropped: true)
                every(actionResolver.resolveOrNilMock).returns(resolvedVariation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "G", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "G", reason: DecisionReason.VARIATION_DROPPED)))
            }

            it("할당된 Variation 으로 평가한다") {
                // given
                let experiment = MockExperiment(type: .abTest, status: .running)

                let variation = MockVariation(id: 320, key: "B")
                every(actionResolver.resolveOrNilMock).returns(variation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "G", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)))
            }
        }

        describe("TargetRuleEvaluator") {

            var targetRuleDeterminer: MockTargetRuleDeterminer!
            var actionResolver: MockActionResolver!
            var sut: TargetRuleEvaluator!

            beforeEach {
                targetRuleDeterminer = MockTargetRuleDeterminer()
                actionResolver = MockActionResolver()
                sut = TargetRuleEvaluator(targetRuleDeterminer: targetRuleDeterminer, actionResolver: actionResolver)
            }

            it("실행중이 아니면 예외 발생") {
                expect(try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(id: 42, type: .featureFlag, status: .draft), user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow()))
                    .to(throwError(HackleError.error("Experiment status must be running [42]")))
            }

            it("featureFlag 타입이 아니면 예외 발생") {
                expect(try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(id: 42, type: .abTest, status: .running), user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow()))
                    .to(throwError(HackleError.error("Experiment type must be featureFlag [42]")))
            }

            it("identifierType에 해당하는 식별자가 없으면 다음 플로우를 실행한다") {
                // given
                let experiment = MockExperiment(id: 42, type: .featureFlag, identifierType: "customId", status: .running)
                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }

            it("타겟룰에 해당하지 않으면 다음 플로우를 실행한다") {
                // given
                let experiment = MockExperiment(id: 42, type: .featureFlag, status: .running)
                every(targetRuleDeterminer.determineTargetRuleOrNilMock).returns(nil)

                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }

            it("타겟룰에 매치했지만 Action에 해당하는 Variation이 결정되지 않으면 예외 발생") {
                // given
                let experiment = MockExperiment(id: 42, type: .featureFlag, status: .running)

                let targetRule = MockTargetRule()
                every(targetRuleDeterminer.determineTargetRuleOrNilMock).returns(targetRule)

                every(actionResolver.resolveOrNilMock).returns(nil)

                // when
                let actual = expect(try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: MockEvaluationFlow()))

                // then
                actual.to(throwError(HackleError.error("FeatureFlag must decide the Variation [42]")))
            }

            it("일치하는 타겟룰이 있는 경우 해당 룰에 해당하는 Variation 으로 결정한다") {
                // given
                let experiment = MockExperiment(id: 42, type: .featureFlag, status: .running)

                let targetRule = MockTargetRule()
                every(targetRuleDeterminer.determineTargetRuleOrNilMock).returns(targetRule)

                let variation = MockVariation(id: 534, key: "E")
                every(actionResolver.resolveOrNilMock).returns(variation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "D", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 534, variationKey: "E", reason: DecisionReason.TARGET_RULE_MATCH)))
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
                expect(try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(id: 42, type: .featureFlag, status: .draft), user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow()))
                    .to(throwError(HackleError.error("Experiment status must be running [42]")))
            }

            it("featureFlag 타입이 아니면 예외 발생") {
                expect(try sut.evaluate(workspace: MockWorkspace(), experiment: MockExperiment(id: 42, type: .abTest, status: .running), user: user, defaultVariationKey: "B", nextFlow: MockEvaluationFlow()))
                    .to(throwError(HackleError.error("Experiment type must be featureFlag [42]")))
            }

            it("identifierType에 해당하는 식별자가 없으면 defaultVariation을 리턴한다") {
                // given
                let experiment = MockExperiment(id: 42, type: .featureFlag, identifierType: "customId", status: .running)
                let variation = MockVariation(id: 42, key: "G")
                every(experiment.getVariationByKeyOrNilMock).returns(variation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "G", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "G", reason: DecisionReason.DEFAULT_RULE)))
            }

            it("기본 룰에 해당하는 Variation을 결정하지 못하면 예외 발생") {
                // given
                let experiment = MockExperiment(id: 42, type: .featureFlag, status: .running)
                every(actionResolver.resolveOrNilMock).returns(nil)

                expect(try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: MockEvaluationFlow()))
                    .to(throwError(HackleError.error("FeatureFlag must decide the Variation [42]")))
            }

            it("기본 룰에 해당하는 Variation 으로 평가한다") {
                // given
                let experiment = MockExperiment(id: 42, type: .featureFlag, status: .running)

                let variation = MockVariation(id: 513, key: "H")
                every(actionResolver.resolveOrNilMock).returns(variation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "A", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 513, variationKey: "H", reason: DecisionReason.DEFAULT_RULE)))
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
                let experiment = MockExperiment()

                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "A", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }


            it("containerId 로 Container 를 찾을 수 없으면 예외 발생") {
                // given
                let experiment = MockExperiment(containerId: 42)

                let workspace = MockWorkspace()
                every(workspace.getContainerOrNilMock).returns(nil)

                // when
                let actual = expect(try sut.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: MockEvaluationFlow()))

                // then
                actual.to(throwError(HackleError.error("container[42]")))
            }

            it("Container 의 Bucket 를 찾을 수 없으면 예외 발생") {
                // given
                let experiment = MockExperiment(containerId: 42)

                let workspace = MockWorkspace()
                let container = MockContainer(bucketId: 320)
                every(workspace.getContainerOrNilMock).returns(container)
                every(workspace.getBucketOrNilMock).returns(nil)

                // when
                let actual = expect(try sut.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: MockEvaluationFlow()))

                // then
                actual.to(throwError(HackleError.error("bucket[320]")))
            }

            it("ContainerGroup 에 속해있으면 nextFlow 로 평가한다") {
                // given
                let experiment = MockExperiment(containerId: 42)

                let workspace = MockWorkspace()
                let container = MockContainer(bucketId: 320)
                every(workspace.getContainerOrNilMock).returns(container)

                let bucket = MockBucket()
                every(workspace.getBucketOrNilMock).returns(bucket)

                every(containerResolver.isUserInContainerGroupMock).returns(true)

                let evaluation = Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try sut.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: "E", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }

            it("ContainerGroup 에 속해있지 않으면 NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT") {
                // given
                let experiment = MockExperiment(type: .abTest, containerId: 22)
                let variation = MockVariation(id: 42, key: "B", isDropped: false)
                every(experiment.getVariationByKeyOrNilMock).returns(variation)

                let workspace = MockWorkspace()
                let container = MockContainer(bucketId: 320)
                every(workspace.getContainerOrNilMock).returns(container)

                let bucket = MockBucket()
                every(workspace.getBucketOrNilMock).returns(bucket)

                every(containerResolver.isUserInContainerGroupMock).returns(false)

                let evaluation = Evaluation(variationId: 999, variationKey: "A", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try sut.evaluate(workspace: workspace, experiment: experiment, user: user, defaultVariationKey: "B", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "B", reason: "NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT")))
            }
        }

        describe("IdentifierEvaluator") {

            var sut: IdentifierEvaluator!

            beforeEach {
                sut = IdentifierEvaluator()
            }

            it("identifierType 에 해당하는 identifier 가 있으면 nextFlow") {
                // given
                let experiment = MockExperiment()
                let evaluation = Evaluation(variationId: 999, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                let nextFlow = MockEvaluationFlow()
                every(nextFlow.evaluateMock).returns(evaluation)

                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "A", nextFlow: nextFlow)

                // then
                expect(actual).to(equal(evaluation))
            }

            it("identifierType 에 해당하는 identifier 가 없으면 IDENTIFIER_NOT_FOUND") {
                // given
                let experiment = MockExperiment(identifierType: "custom_id")
                let variation = MockVariation(id: 42, key: "B", isDropped: false)
                every(experiment.getVariationByKeyOrNilMock).returns(variation)


                // when
                let actual = try sut.evaluate(workspace: MockWorkspace(), experiment: experiment, user: user, defaultVariationKey: "A", nextFlow: MockEvaluationFlow())

                // then
                expect(actual).to(equal(Evaluation(variationId: 42, variationKey: "B", reason: "IDENTIFIER_NOT_FOUND")))
            }
        }
    }
}
