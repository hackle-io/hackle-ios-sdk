import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultHackleCoreSpecs: QuickSpec {

    // MARK: - Test infra

    class MockWorkspaceConfigFetcher: WorkspaceConfigFetcher {
        var workspace: WorkspaceConfig?
        init(workspace: WorkspaceConfig? = nil) {
            self.workspace = workspace
        }
        func fetch() -> WorkspaceConfig? {
            workspace
        }
    }

    static func core(workspace: WorkspaceConfig?, eventProcessor: UserEventProcessor) -> DefaultHackleCore {
        let context = EvaluationContext()
        let impressionStorage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
        let hiddenStorage = DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
        context.register(impressionStorage)
        context.register(hiddenStorage)

        let evaluateProcessor = EvaluateProcessor.create(
            context: context,
            clock: SystemClock.shared,
            eventProcessor: eventProcessor,
            overrideStorage: DelegatingManualOverrideStorage(storages: []),
            impressionStorage: impressionStorage,
            hiddenStorage: hiddenStorage
        )
        let fetcher = MockWorkspaceConfigFetcher(workspace: workspace)
        let decisionProcessor = LocalDecisionProcessor(workspaceFetcher: fetcher, evaluateProcessor: evaluateProcessor)

        // workspaceFetcher used by track() only
        let workspaceFetcher = MockWorkspaceFetcher()
        every(workspaceFetcher.fetchMock).returns(workspace)

        return DefaultHackleCore(
            workspaceFetcher: workspaceFetcher,
            decisionProcessor: decisionProcessor,
            eventProcessor: eventProcessor,
            clock: SystemClock.shared
        )
    }

    override class func spec() {

        let user = HackleUser.of(userId: "test")

        describe("experiment") {

            it("Workspace 를 가져올 수 없으면 기본그룹으로 결정한다") {
                let sut = core(workspace: nil, eventProcessor: InMemoryUserEventProcessor())
                let actual = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "J")
                expect(actual.variation) == "J"
                expect(actual.reason) == DecisionReason.SDK_NOT_READY
            }

            it("experimentKey 에 대한 Experiment 를 찾을 수 없으면 기본그룹으로 결정한다") {
                let workspace = MockWorkspace()
                every(workspace.getExperimentOrNilMock).returns(nil)
                let sut = core(workspace: workspace, eventProcessor: InMemoryUserEventProcessor())

                let actual = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "C")
                expect(actual.variation) == "C"
                expect(actual.reason) == DecisionReason.EXPERIMENT_NOT_FOUND
            }

            it("평가 결과로 결정하고 노출 이벤트를 기록한다") {
                let workspace = MockWorkspace()
                every(workspace.getExperimentOrNilMock).returns(experiment(type: .abTest, status: .draft))
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = core(workspace: workspace, eventProcessor: eventProcessor)

                let actual = try sut.experiment(experimentKey: 42, user: user, defaultVariationKey: "A")

                expect(actual.reason) == DecisionReason.EXPERIMENT_DRAFT
                expect(eventProcessor.processedEvents.count) == 1
                expect(eventProcessor.processedEvents[0]).to(beAnInstanceOf(UserEvents.Exposure.self))
            }
        }

        describe("experiments") {

            it("Workspace 를 가져올 수 없으면 비어있는 list 를 리턴한다") {
                let sut = core(workspace: nil, eventProcessor: InMemoryUserEventProcessor())
                let actual = try sut.experiments(user: user)
                expect(actual.count) == 0
            }

            it("모든 실험에 대한 분배 결과를 리턴하고 노출 이벤트를 기록하지 않는다") {
                let workspace = MockWorkspace(experiments: [
                    experiment(id: 1, key: 1, type: .abTest, status: .draft),
                    experiment(id: 3, key: 3, type: .abTest, status: .draft)
                ])
                every(workspace.getExperimentOrNilMock).answers { key in
                    workspace.experiments.first { $0.key == key }
                }
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = core(workspace: workspace, eventProcessor: eventProcessor)

                let actual = try sut.experiments(user: user)

                expect(actual.count) == 2
                expect(eventProcessor.processedEvents.count) == 0
            }
        }

        describe("featureFlag") {

            it("Workspace 를 가져올 수 없으면 off 로 결정한다") {
                let sut = core(workspace: nil, eventProcessor: InMemoryUserEventProcessor())
                let actual = try sut.featureFlag(featureKey: 42, user: user)
                expect(actual.isOn) == false
                expect(actual.reason) == DecisionReason.SDK_NOT_READY
            }

            it("featureKey 에 대한 FeatureFlag 를 찾을 수 없으면 off 로 결정한다") {
                let workspace = MockWorkspace()
                every(workspace.getFeatureFlagOrNilMock).returns(nil)
                let sut = core(workspace: workspace, eventProcessor: InMemoryUserEventProcessor())

                let actual = try sut.featureFlag(featureKey: 42, user: user)
                expect(actual.isOn) == false
                expect(actual.reason) == DecisionReason.FEATURE_FLAG_NOT_FOUND
            }

            it("평가 결과로 결정하고 노출 이벤트를 기록한다") {
                let workspace = MockWorkspace()
                every(workspace.getFeatureFlagOrNilMock).returns(experiment(type: .featureFlag, status: .draft))
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = core(workspace: workspace, eventProcessor: eventProcessor)

                let actual = try sut.featureFlag(featureKey: 42, user: user)

                expect(actual.reason) == DecisionReason.EXPERIMENT_DRAFT
                expect(eventProcessor.processedEvents.count) == 1
                expect(eventProcessor.processedEvents[0]).to(beAnInstanceOf(UserEvents.Exposure.self))
            }
        }

        describe("featureFlags") {

            it("Workspace 가 없으면 emptyList") {
                let sut = core(workspace: nil, eventProcessor: InMemoryUserEventProcessor())
                let actual = try sut.featureFlags(user: user)
                expect(actual.count) == 0
            }

            it("모든 기능플래그에 대한 분배 결과를 리턴하고 노출 이벤트를 기록하지 않는다") {
                let workspace = MockWorkspace(featureFlags: [
                    experiment(id: 1, key: 1, type: .featureFlag, status: .draft),
                    experiment(id: 3, key: 3, type: .featureFlag, status: .draft)
                ])
                every(workspace.getFeatureFlagOrNilMock).answers { key in
                    workspace.featureFlags.first { $0.key == key }
                }
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = core(workspace: workspace, eventProcessor: eventProcessor)

                let actual = try sut.featureFlags(user: user)

                expect(actual.count) == 2
                expect(eventProcessor.processedEvents.count) == 0
            }
        }

        describe("remoteConfig") {

            it("단일 remoteConfig 조회 시 이벤트를 기록한다") {
                let parameter = RemoteConfigParameter(id: 1, key: "rc", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 1, rawValue: .string("dv")))
                let workspace = MockWorkspace()
                every(workspace.getRemoteConfigParameterMock).returns(parameter)
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = core(workspace: workspace, eventProcessor: eventProcessor)

                let actual = try sut.remoteConfig(parameterKey: "rc", user: user, defaultValue: .string("default"))

                expect(actual.reason) == DecisionReason.DEFAULT_RULE
                expect(eventProcessor.processedEvents.count) == 1
                expect(eventProcessor.processedEvents[0]).to(beAnInstanceOf(UserEvents.RemoteConfig.self))
            }
        }
    }
}
