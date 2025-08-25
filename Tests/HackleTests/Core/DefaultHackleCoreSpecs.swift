import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultHackleCoreSpecs: QuickSpec {
    override func spec() {

        let user = HackleUser.of(userId: "test")

        var experimentEvaluator: MockEvaluator!
        var remoteConfigEvaluator: MockEvaluator!
        var inAppMessageEvaluator: MockEvaluator!
        var workspaceFetcher: MockWorkspaceFetcher!
        var eventFactory: MockUserEventFactory!
        var eventProcessor: MockUserEventProcessor!
        var sut: DefaultHackleCore!

        beforeEach {
            experimentEvaluator = MockEvaluator()
            remoteConfigEvaluator = MockEvaluator()
            inAppMessageEvaluator = MockEvaluator()
            workspaceFetcher = MockWorkspaceFetcher()
            eventFactory = MockUserEventFactory()
            eventProcessor = MockUserEventProcessor()
            sut = DefaultHackleCore(
                experimentEvaluator: experimentEvaluator,
                remoteConfigEvaluator: remoteConfigEvaluator,
                inAppMessageEvaluator: inAppMessageEvaluator,
                workspaceFetcher: workspaceFetcher,
                eventFactory: eventFactory,
                eventProcessor: eventProcessor,
                clock: FixedClock(date: Date(timeIntervalSince1970: 42))
            )
        }

        describe("experiment") {

            context("Workspace 를 가져올 수 없으면") {
                it("기본그룹으로 결졍한다") {
                    // given
                    every(workspaceFetcher.fetchMock).returns(nil)

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

                    every(workspaceFetcher.fetchMock).returns(workspace)

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
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(experiment())

                    every(workspaceFetcher.fetchMock).returns(workspace)

                    let config = ParameterConfigurationEntity(id: 32, parameters: [:])
                    let evaluation = experimentEvaluation(reason: DecisionReason.TRAFFIC_ALLOCATED, targetEvaluations: [], experiment: experiment(), variationId: 320, variationKey: "B", config: config)
                    experimentEvaluator.returns = evaluation

                    // when
                    let actual = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "A")

                    // then
                    expect(actual.variation) == "B"
                    expect(actual.reason) == DecisionReason.TRAFFIC_ALLOCATED
                    expect(actual.config as? ParameterConfigurationEntity) === config
                }

                it("평과 결과로 노출 이벤트를 처리한다") {
                    // given
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(experiment())

                    every(workspaceFetcher.fetchMock).returns(workspace)

                    let evaluation = experimentEvaluation(reason: DecisionReason.TRAFFIC_ALLOCATED, targetEvaluations: [], experiment: experiment(), variationId: 320, variationKey: "B", config: nil)
                    experimentEvaluator.returns = evaluation

                    eventFactory.events = [MockUserEvent()]

                    // when
                    _ = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "A")

                    // then
                    verify(exactly: 1) {
                        eventProcessor.processMock
                    }
                }
            }
        }

        describe("experiments") {
            context("Workspace 를 가져올 수 없으면") {
                it("비어있는 list 를 리턴한다") {
                    // given
                    every(workspaceFetcher.fetchMock).returns(nil)

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
                    experimentEvaluation(reason: DecisionReason.EXPERIMENT_PAUSED, variationId: 10, variationKey: "A", config: config42),
                    experimentEvaluation(reason: DecisionReason.EXPERIMENT_COMPLETED, variationId: 30, variationKey: "B", config: config43),
                    experimentEvaluation(reason: DecisionReason.OVERRIDDEN, variationId: 40, variationKey: "C", config: nil),
                    experimentEvaluation(reason: DecisionReason.TRAFFIC_ALLOCATED, variationId: 70, variationKey: "A", config: nil)
                ]
                let evaluator = EvaluatorStub(evaluations: evaluations)
                let workspace = MockWorkspace(experiments: [MockExperiment(key: 1), MockExperiment(key: 3), MockExperiment(key: 4), MockExperiment(key: 7)])
                every(workspaceFetcher.fetchMock).returns(workspace)

                let sut = DefaultHackleCore(
                    experimentEvaluator: evaluator,
                    remoteConfigEvaluator: remoteConfigEvaluator,
                    inAppMessageEvaluator: inAppMessageEvaluator,
                    workspaceFetcher: workspaceFetcher,
                    eventFactory: eventFactory,
                    eventProcessor: eventProcessor,
                    clock: FixedClock(date: Date(timeIntervalSince1970: 42))
                )

                // when
                let actual = try sut.experiments(user: user)

                // then
                expect(actual.count) == 4

                expect(actual[0].0.key) == 1
                expect(actual[0].1.variation) == "A"
                expect(actual[0].1.reason) == DecisionReason.EXPERIMENT_PAUSED
                expect(actual[0].1.config) === config42

                expect(actual[1].0.key) == 3
                expect(actual[1].1.variation) == "B"
                expect(actual[1].1.reason) == DecisionReason.EXPERIMENT_COMPLETED
                expect(actual[1].1.config) === config43

                expect(actual[2].0.key) == 4
                expect(actual[2].1.variation) == "C"
                expect(actual[2].1.reason) == DecisionReason.OVERRIDDEN
                expect(actual[2].1.config) === EmptyParameterConfig.instance

                expect(actual[3].0.key) == 7
                expect(actual[3].1.variation) == "A"
                expect(actual[3].1.reason) == DecisionReason.TRAFFIC_ALLOCATED
                expect(actual[3].1.config) === EmptyParameterConfig.instance

                verify(exactly: 0) {
                    eventProcessor.processMock
                }
            }
        }

        class EvaluatorStub: Evaluator {

            private let experimentEvaluations: [ExperimentEvaluation]
            private var experimentEvaluateCount = -1

            init(evaluations: [ExperimentEvaluation]) {
                self.experimentEvaluations = evaluations
            }

            func evaluate<Evaluation>(request: EvaluatorRequest, context: EvaluatorContext) throws -> Evaluation where Evaluation: EvaluatorEvaluation {
                experimentEvaluateCount = experimentEvaluateCount + 1
                return experimentEvaluations[experimentEvaluateCount] as! Evaluation
            }
        }

        describe("featureFlag") {

            context("Workspace 를 가져올 수 없으면") {
                it("off 로 결졍한다") {
                    // given
                    every(workspaceFetcher.fetchMock).returns(nil)

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

                    every(workspaceFetcher.fetchMock).returns(workspace)

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

                    every(workspaceFetcher.fetchMock).returns(workspace)

                    let evaluation = experimentEvaluation(reason: DecisionReason.TARGET_RULE_MATCH, variationId: 320, variationKey: "B")
                    experimentEvaluator.returns = evaluation

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

                    every(workspaceFetcher.fetchMock).returns(workspace)

                    let evaluation = experimentEvaluation(reason: DecisionReason.DEFAULT_RULE, variationId: 320, variationKey: "A")
                    experimentEvaluator.returns = evaluation

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

                    every(workspaceFetcher.fetchMock).returns(workspace)

                    let config = ParameterConfigurationEntity(id: 32, parameters: [:])

                    let evaluation = experimentEvaluation(reason: DecisionReason.DEFAULT_RULE, variationId: 320, variationKey: "A", config: config)
                    experimentEvaluator.returns = evaluation

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

                    every(workspaceFetcher.fetchMock).returns(workspace)

                    let evaluation = experimentEvaluation(reason: DecisionReason.DEFAULT_RULE, variationId: 320, variationKey: "A")
                    experimentEvaluator.returns = evaluation
                    eventFactory.events = [MockUserEvent()]

                    // when
                    _ = try sut.featureFlag(featureKey: 42, user: user)

                    // then
                    verify(exactly: 1) {
                        eventProcessor.processMock
                    }
                }
            }
        }

        describe("featureFlags") {
            it("Workspace 가 없으면 emptyList") {
                // given
                every(workspaceFetcher.fetchMock).returns(nil)

                // when
                let actual = try sut.featureFlags(user: user)

                // then
                expect(actual.count) == 0
            }

            it("모든 기능플래그에 대한 분배 결과를 리턴한다") {
                // given
                let config42 = ParameterConfigurationEntity(id: 42, parameters: [:])
                let config43 = ParameterConfigurationEntity(id: 43, parameters: [:])
                let evaluations = [
                    experimentEvaluation(reason: DecisionReason.FEATURE_FLAG_INACTIVE, variationId: 10, variationKey: "A", config: config42),
                    experimentEvaluation(reason: DecisionReason.INDIVIDUAL_TARGET_MATCH, variationId: 30, variationKey: "B", config: config43),
                    experimentEvaluation(reason: DecisionReason.TARGET_RULE_MATCH, variationId: 40, variationKey: "B", config: nil),
                    experimentEvaluation(reason: DecisionReason.DEFAULT_RULE, variationId: 70, variationKey: "A", config: nil)
                ]
                let evaluator = EvaluatorStub(evaluations: evaluations)
                let workspace = MockWorkspace(featureFlags: [MockExperiment(key: 1), MockExperiment(key: 3), MockExperiment(key: 4), MockExperiment(key: 7)])
                every(workspaceFetcher.fetchMock).returns(workspace)

                let sut = DefaultHackleCore(
                    experimentEvaluator: evaluator,
                    remoteConfigEvaluator: remoteConfigEvaluator,
                    inAppMessageEvaluator: inAppMessageEvaluator,
                    workspaceFetcher: workspaceFetcher,
                    eventFactory: eventFactory,
                    eventProcessor: eventProcessor,
                    clock: FixedClock(date: Date(timeIntervalSince1970: 42))
                )

                // when
                let actual = try sut.featureFlags(user: user)

                // then
                expect(actual.count) == 4

                expect(actual[0].0.key) == 1
                expect(actual[0].1.isOn) == false
                expect(actual[0].1.reason) == DecisionReason.FEATURE_FLAG_INACTIVE
                expect(actual[0].1.config) === config42

                expect(actual[1].0.key) == 3
                expect(actual[1].1.isOn) == true
                expect(actual[1].1.reason) == DecisionReason.INDIVIDUAL_TARGET_MATCH
                expect(actual[1].1.config) === config43

                expect(actual[2].0.key) == 4
                expect(actual[2].1.isOn) == true
                expect(actual[2].1.reason) == DecisionReason.TARGET_RULE_MATCH
                expect(actual[2].1.config) === EmptyParameterConfig.instance

                expect(actual[3].0.key) == 7
                expect(actual[3].1.isOn) == false
                expect(actual[3].1.reason) == DecisionReason.DEFAULT_RULE
                expect(actual[3].1.config) === EmptyParameterConfig.instance

                verify(exactly: 0) {
                    eventProcessor.processMock
                }
            }
        }
    }
}
