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

                    let config = ParameterConfigurationEntity(id: 32, parameters: [:])
                    every(evaluator.evaluateExperimentMock).returns(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED, config: config))

                    // when
                    let actual = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "A")

                    // then
                    expect(actual.variation) == "B"
                    expect(actual.reason) == DecisionReason.TRAFFIC_ALLOCATED
                    expect(actual.config as? ParameterConfigurationEntity) === config
                }

                it("평과 결과로 노출 이벤트를 처리한다") {
                    // given
                    let experiment = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(experiment)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateExperimentMock).returns(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TRAFFIC_ALLOCATED, config: nil))

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
                let config42 = ParameterConfigurationEntity(id: 42, parameters: [:])
                let config43 = ParameterConfigurationEntity(id: 43, parameters: [:])
                let evaluations = [
                    Evaluation(variationId: 10, variationKey: "A", reason: DecisionReason.EXPERIMENT_PAUSED, config: config42),
                    Evaluation(variationId: 30, variationKey: "B", reason: DecisionReason.EXPERIMENT_COMPLETED, config: config43),
                    Evaluation(variationId: 40, variationKey: "C", reason: DecisionReason.OVERRIDDEN, config: nil),
                    Evaluation(variationId: 70, variationKey: "A", reason: DecisionReason.TRAFFIC_ALLOCATED, config: nil),
                ]
                let evaluator = EvaluatorStub(evaluations: evaluations)
                let workspace = MockWorkspace(experiments: [MockExperiment(key: 1), MockExperiment(key: 3), MockExperiment(key: 4), MockExperiment(key: 7)])
                every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                let sut = DefaultHackleInternalApp(evaluator: evaluator, workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor)

                // when
                let actual = try sut.experiments(user: user)

                // then
                expect(actual.count) == 4

                expect(actual[1]!.variation) == "A"
                expect(actual[1]!.reason) == DecisionReason.EXPERIMENT_PAUSED
                expect(actual[1]!.config) === config42

                expect(actual[3]!.variation) == "B"
                expect(actual[3]!.reason) == DecisionReason.EXPERIMENT_COMPLETED
                expect(actual[3]!.config) === config43

                expect(actual[4]!.variation) == "C"
                expect(actual[4]!.reason) == DecisionReason.OVERRIDDEN
                expect(actual[4]!.config) === EmptyParameterConfig.instance

                expect(actual[7]!.variation) == "A"
                expect(actual[7]!.reason) == DecisionReason.TRAFFIC_ALLOCATED
                expect(actual[7]!.config) === EmptyParameterConfig.instance
            }

            class EvaluatorStub: Evaluator {

                private let experimentEvaluations: [Evaluation]
                private var experimentEvaluateCount = -1

                init(evaluations: [Evaluation]) {
                    self.experimentEvaluations = evaluations
                }

                func evaluateExperiment(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: Variation.Key) throws -> Evaluation {
                    experimentEvaluateCount = experimentEvaluateCount + 1
                    return experimentEvaluations[experimentEvaluateCount]
                }

                func evaluateRemoteConfig(workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigEvaluation {
                    fatalError("evaluateRemoteConfig(workspace:parameter:user:defaultValue:) has not been implemented")
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
                    expect(actual.config) === EmptyParameterConfig.instance
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
                    expect(actual.config) === EmptyParameterConfig.instance
                }
            }

            context("featureKey 에 해당하는 FeatureFlag 가 있는 경우") {
                it("평가한 결과가 A 그룹이 아닌경우 on 으로 결정한다") {
                    // given
                    let featureFlag = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getFeatureFlagOrNilMock).returns(featureFlag)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateExperimentMock).returns(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.TARGET_RULE_MATCH, config: nil))

                    // when
                    let actual = try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    expect(actual.isOn) == true
                    expect(actual.reason) == DecisionReason.TARGET_RULE_MATCH
                    expect(actual.config) === EmptyParameterConfig.instance
                }


                it("평가한 결과가 A 그룹인 경우 off 로 결정한다") {
                    // given
                    let featureFlag = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getFeatureFlagOrNilMock).returns(featureFlag)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateExperimentMock).returns(Evaluation(variationId: 320, variationKey: "A", reason: DecisionReason.DEFAULT_RULE, config: nil))

                    // when
                    let actual = try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    expect(actual.isOn) == false
                    expect(actual.reason) == DecisionReason.DEFAULT_RULE
                    expect(actual.config) === EmptyParameterConfig.instance
                }

                it("평가된 Config 를 사용한다") {
                    // given
                    let featureFlag = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getFeatureFlagOrNilMock).returns(featureFlag)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    let config = ParameterConfigurationEntity(id: 32, parameters: [:])
                    every(evaluator.evaluateExperimentMock).returns(Evaluation(variationId: 320, variationKey: "A", reason: DecisionReason.DEFAULT_RULE, config: config))

                    // when
                    let actual = try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    expect(actual.config) === config
                }


                it("평과 결과로 노출 이벤트를 처리한다") {
                    // given
                    let featureFlag = MockExperiment()
                    let workspace = MockWorkspace()
                    every(workspace.getFeatureFlagOrNilMock).returns(featureFlag)

                    every(workspaceFetcher.getWorkspaceOrNilMock).returns(workspace)

                    every(evaluator.evaluateExperimentMock).returns(Evaluation(variationId: 320, variationKey: "B", reason: DecisionReason.INDIVIDUAL_TARGET_MATCH, config: nil))

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
