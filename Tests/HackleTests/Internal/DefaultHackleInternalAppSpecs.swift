import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultHackleInternalAppSpecs: QuickSpec {
    override func spec() {

        let user = HackleUser.of(userId: "test")

        var evaluator: MockEvaluator!
        var workspaceFetcher: MockWorkspaceFetcher!
        var eventProcessor: MockUserEventProcessor!
        var sut: DefaultHackleInternalApp!

        beforeEach {
            evaluator = MockEvaluator()
            workspaceFetcher = MockWorkspaceFetcher()
            eventProcessor = MockUserEventProcessor()
            sut = DefaultHackleInternalApp(evaluator: evaluator, workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor)
        }


        describe("experiment") {

            context("Workspace 를 가져올 수 없으면") {
                it("기본그룹으로 결졍한다") {
                    // given
                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(nil)

                    // when
                    let actual = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "J")

                    // then
                    expect(actual.variation) == "J"
                    expect(actual.reason) == DecisionReason.SDK_NOT_READY
                }
            }

            context("experimentKey 에 대한 Experiment 를 찾을 수 없으면") {
                it("기본그룹으로 결정한다") {
                    // given
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(nil)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    // when
                    let actual = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "C")

                    // then
                    expect(actual.variation) == "C"
                    expect(actual.reason) == DecisionReason.EXPERIMENT_NOT_FOUND
                }
            }

            context("experimentKey 에 해당하는 Experiment 가 있는 경우") {
                it("평가한 결과로 결정한다") {
                    // given
                    let experiment = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(experiment)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateMock).returns(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED))

                    // when
                    let actual = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "A")

                    // then
                    expect(actual.variation) == "B"
                    expect(actual.reason) == DecisionReason.TRAFFIC_ALLOCATED
                }

                it("평과 결과로 노출 이벤트를 처리한다") {
                    // given
                    let experiment = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(experiment)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateMock).returns(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED))

                    // when
                    try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "A")

                    // then
                    verify(exactly: 1) {
                        eventProcessor.processMock
                    }
                }
            }
        }

        describe("experiments") {
            context("Workspace 를 가져올 수 없으면") {
                it("비어있는 dictionary 를 리턴한다") {
                    // given
                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(nil)

                    // when
                    let actual = try sut.experiments(user: user)

                    // then
                    expect(actual.count) == 0
                }
            }

            it("모든 실험에 대한 분배 결과를 리턴한다") {
                // given
                let evaluations = [
                    Evaluation(variationId: 10, variationKey: "A", reason: DecisionReason.EXPERIMENT_PAUSED),
                    Evaluation(variationId: 30, variationKey: "B", reason: DecisionReason.EXPERIMENT_COMPLETED),
                    Evaluation(variationId: 40, variationKey: "C", reason: DecisionReason.OVERRIDDEN),
                    Evaluation(variationId: 70, variationKey: "A", reason: DecisionReason.TRAFFIC_ALLOCATED),
                ]
                let evaluator = EvaluatorStub(evaluations: evaluations)
                let workspace = MockWorkspace(experiments: [MockExperiment(key: 1), MockExperiment(key: 3), MockExperiment(key: 4), MockExperiment(key: 7)])
                every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                let sut = DefaultHackleInternalApp(evaluator: evaluator, workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor)

                // when
                let actual = try sut.experiments(user: user)

                // then
                expect(actual.count) == 4

                expect(actual[1]?.variation) == "A"
                expect(actual[1]?.reason) == DecisionReason.EXPERIMENT_PAUSED

                expect(actual[3]?.variation) == "B"
                expect(actual[3]?.reason) == DecisionReason.EXPERIMENT_COMPLETED

                expect(actual[4]?.variation) == "C"
                expect(actual[4]?.reason) == DecisionReason.OVERRIDDEN

                expect(actual[7]?.variation) == "A"
                expect(actual[7]?.reason) == DecisionReason.TRAFFIC_ALLOCATED
            }

            class EvaluatorStub: Evaluator {

                private let evaluations: [Evaluation]
                private var i = -1

                init(evaluations: [Evaluation]) {
                    self.evaluations = evaluations
                }

                func evaluate(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Evaluation {
                    i = i + 1
                    return evaluations[i]
                }
            }
        }


        describe("featureFlag") {

            context("Workspace 를 가져올 수 없으면") {
                it("off 로 결졍한다") {
                    // given
                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(nil)

                    // when
                    let actual = try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    expect(actual.isOn) == false
                    expect(actual.reason) == DecisionReason.SDK_NOT_READY
                }
            }

            context("featureKey 에 대한 FeatureFlag 를 찾을 수 없으면") {
                it("off 로 결졍한다") {
                    // given
                    let workspace = MockWorkspace()
                    every(workspace.getFeatureFlagOrNilMock).returns(nil)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    // when
                    let actual = try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    expect(actual.isOn) == false
                    expect(actual.reason) == DecisionReason.FEATURE_FLAG_NOT_FOUND
                }
            }

            context("featureKey 에 해당하는 FeatureFlag 가 있는 경우") {
                it("평가한 결과가 A 그룹이 아닌경우 on 으로 결정한다") {
                    // given
                    let featureFlag = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getFeatureFlagOrNilMock).returns(featureFlag)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateMock).returns(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TARGET_RULE_MATCH))

                    // when
                    let actual = try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    expect(actual.isOn) == true
                    expect(actual.reason) == DecisionReason.TARGET_RULE_MATCH
                }


                it("평가한 결과가 A 그룹인 경우 off 로 결정한다") {
                    // given
                    let featureFlag = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getFeatureFlagOrNilMock).returns(featureFlag)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateMock).returns(Evaluation(variationId: 320, variationKey: "A", reason: DecisionReason.DEFAULT_RULE))

                    // when
                    let actual = try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    expect(actual.isOn) == false
                    expect(actual.reason) == DecisionReason.DEFAULT_RULE
                }


                it("평과 결과로 노출 이벤트를 처리한다") {
                    // given
                    let featureFlag = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getFeatureFlagOrNilMock).returns(featureFlag)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateMock).returns(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.INDIVIDUAL_TARGET_MATCH))

                    // when
                    try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    verify(exactly: 1) {
                        eventProcessor.processMock
                    }
                }
            }
        }
    }
}
