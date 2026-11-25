import Foundation
import Quick
import Nimble
@testable import Hackle

/// Regression: bulk APIs (experiments/featureFlags) MUST NOT record exposure events (request.record == false),
/// while single experiment / featureFlag / remoteConfig DO record (request.record == true).
class LocalDecisionProcessorSpecs: QuickSpec {

    final class StubWorkspaceConfigFetcher: WorkspaceConfigFetcher {
        let workspace: WorkspaceConfig?
        init(_ workspace: WorkspaceConfig?) { self.workspace = workspace }
        func workspace(user: HackleUser) -> WorkspaceConfig? { workspace }
    }

    static func evaluateProcessor(eventProcessor: UserEventProcessor) -> EvaluateProcessor {
        let context = HackleCoreContext()
        let impressionStorage = DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository())
        let hiddenStorage = DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository())
        context.register(impressionStorage)
        context.register(hiddenStorage)

        return EvaluateProcessor.create(
            context: context,
            clock: SystemClock.shared,
            eventProcessor: eventProcessor,
            overrideStorage: DelegatingManualOverrideStorage(storages: []),
            impressionStorage: impressionStorage,
            hiddenStorage: hiddenStorage
        )
    }

    static func processor(workspace: WorkspaceConfig, eventProcessor: UserEventProcessor) -> LocalDecisionProcessor {
        LocalDecisionProcessor(
            workspaceFetcher: StubWorkspaceConfigFetcher(workspace),
            evaluateProcessor: evaluateProcessor(eventProcessor: eventProcessor)
        )
    }

    static func devToolsProcessor(workspace: WorkspaceConfig, eventProcessor: UserEventProcessor) -> LocalDevToolsDecisionProcessor {
        LocalDevToolsDecisionProcessor(
            workspaceFetcher: StubWorkspaceConfigFetcher(workspace),
            evaluateProcessor: evaluateProcessor(eventProcessor: eventProcessor)
        )
    }

    override class func spec() {

        let user = HackleUser.of(userId: "test")

        describe("record semantics") {

            it("single experiment records an exposure event (record == true)") {
                let workspace = MockWorkspace()
                every(workspace.getExperimentOrNilMock).returns(experiment(type: .abTest, status: .draft))
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = processor(workspace: workspace, eventProcessor: eventProcessor)

                _ = try sut.experiment(experimentKey: 1, user: user)

                expect(eventProcessor.processedEvents.count) == 1
            }

            it("single featureFlag records an exposure event (record == true)") {
                let workspace = MockWorkspace()
                every(workspace.getFeatureFlagOrNilMock).returns(experiment(type: .featureFlag, status: .draft))
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = processor(workspace: workspace, eventProcessor: eventProcessor)

                _ = try sut.featureFlag(featureKey: 1, user: user)

                expect(eventProcessor.processedEvents.count) == 1
            }

            it("single remoteConfig records a remote-config event (record == true)") {
                let parameter = RemoteConfigParameterEntity(id: 1, key: "rc", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 1, rawValue: .string("dv")))
                let workspace = MockWorkspace()
                every(workspace.getRemoteConfigParameterMock).returns(parameter)
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = processor(workspace: workspace, eventProcessor: eventProcessor)

                _ = try sut.remoteConfig(parameterKey: "rc", user: user, defaultValue: .string("default"))

                expect(eventProcessor.processedEvents.count) == 1
            }

            it("bulk experiments(user) does NOT record exposure events (record == false)") {
                let workspace = MockWorkspace(experiments: [
                    experiment(id: 1, key: 1, type: .abTest, status: .draft),
                    experiment(id: 2, key: 2, type: .abTest, status: .draft),
                    experiment(id: 3, key: 3, type: .abTest, status: .draft)
                ])
                every(workspace.getExperimentOrNilMock).answers { key in
                    workspace.experiments.first { $0.key == key }
                }
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = processor(workspace: workspace, eventProcessor: eventProcessor)

                let decisions = try sut.experiments(user: user)

                expect(decisions.count) == 3
                expect(eventProcessor.processedEvents.count) == 0
            }

            it("bulk featureFlags(user) does NOT record exposure events (record == false)") {
                let workspace = MockWorkspace(featureFlags: [
                    experiment(id: 1, key: 1, type: .featureFlag, status: .draft),
                    experiment(id: 2, key: 2, type: .featureFlag, status: .draft),
                    experiment(id: 3, key: 3, type: .featureFlag, status: .draft)
                ])
                every(workspace.getFeatureFlagOrNilMock).answers { key in
                    workspace.featureFlags.first { $0.key == key }
                }
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = devToolsProcessor(workspace: workspace, eventProcessor: eventProcessor)

                let decisions = try sut.featureFlags(user: user)

                expect(decisions.count) == 3
                expect(eventProcessor.processedEvents.count) == 0
            }

            it("bulk remoteConfigs(user) evaluates every parameter with its own type and records nothing") {
                let p1 = RemoteConfigParameterEntity(id: 1, key: "a", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 11, rawValue: .string("x")))
                let p2 = RemoteConfigParameterEntity(id: 2, key: "b", type: .number, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 22, rawValue: .double(3)))
                let workspace = MockWorkspace(remoteConfigParameters: [p1, p2])
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = devToolsProcessor(workspace: workspace, eventProcessor: eventProcessor)

                let evaluations = try sut.remoteConfigs(user: user)

                expect(evaluations.map { $0.parameter.key }) == ["a", "b"]
                expect(evaluations.map { $0.remoteConfigResult.value?.id }) == [11, 22]
                expect(eventProcessor.processedEvents.count) == 0
            }

            it("bulk inAppMessages(user, timestamp) judges every message in trigger scope and records nothing") {
                let workspace = MockWorkspace(inAppMessages: [InAppMessageEntity.create(id: 1, key: 1), InAppMessageEntity.create(id: 2, key: 2, status: .pause)])
                let eventProcessor = InMemoryUserEventProcessor()
                let sut = devToolsProcessor(workspace: workspace, eventProcessor: eventProcessor)

                let evaluations = try sut.inAppMessages(user: user, timestamp: Date())

                expect(evaluations.map { $0.inAppMessage.key }) == [1, 2]
                expect(evaluations[1].eligibilityResult.isEligible) == false
                expect(eventProcessor.processedEvents.count) == 0
            }
        }
    }
}
