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
        func fetch() -> WorkspaceConfig? { workspace }
    }

    static func processor(workspace: WorkspaceConfig, eventProcessor: UserEventProcessor) -> LocalDecisionProcessor {
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
        return LocalDecisionProcessor(
            workspaceFetcher: StubWorkspaceConfigFetcher(workspace),
            evaluateProcessor: evaluateProcessor
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

                _ = try sut.experiment(experimentKey: 1, user: user, defaultVariationKey: "A")

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
                let parameter = RemoteConfigParameter(id: 1, key: "rc", type: .string, identifierType: "$id", targetRules: [], defaultValue: RemoteConfigParameter.Value(id: 1, rawValue: .string("dv")))
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
                let sut = processor(workspace: workspace, eventProcessor: eventProcessor)

                let decisions = try sut.featureFlags(user: user)

                expect(decisions.count) == 3
                expect(eventProcessor.processedEvents.count) == 0
            }
        }
    }
}
