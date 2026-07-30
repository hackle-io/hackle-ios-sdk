import Foundation
import Quick
import Nimble
@testable import Hackle

class RemoteDecisionProcessorSpecs: QuickSpec {
    override class func spec() {

        var fetcher: MockWorkspaceEvaluationFetcher!
        var eventProcessor: MockUserEventProcessor!
        var sut: RemoteDecisionProcessor!

        beforeEach {
            fetcher = MockWorkspaceEvaluationFetcher()
            eventProcessor = MockUserEventProcessor()
            let evaluateProcessor = EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: eventProcessor,
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage.create(suiteName: "RemoteDecisionProcessorSpecs"),
                hiddenStorage: DefaultInAppMessageHiddenStorage.create(suiteName: "RemoteDecisionProcessorSpecs")
            )
            sut = RemoteDecisionProcessor(workspaceFetcher: fetcher, evaluateProcessor: evaluateProcessor)
        }

        describe("experiment") {
            it("SDK_NOT_READY when workspace evaluation is absent") {
                fetcher.returns = nil
                let decision = try sut.experiment(experimentKey: 10, user: HackleUser.builder().build())
                expect(decision.variation).to(equal("A"))
                expect(decision.reason).to(equal(DecisionReason.SDK_NOT_READY))
            }

            it("EXPERIMENT_NOT_FOUND when key is not evaluated") {
                fetcher.returns = MockWorkspaceEvaluation()
                let decision = try sut.experiment(experimentKey: 10, user: HackleUser.builder().build())
                expect(decision.reason).to(equal(DecisionReason.EXPERIMENT_NOT_FOUND))
            }

            it("returns server-evaluated variation and records exposure") {
                let workspace = MockWorkspaceEvaluation()
                workspace.experimentResults = [experimentRemoteResult(id: 1, key: 10, reason: DecisionReason.TRAFFIC_ALLOCATED)]
                fetcher.returns = workspace

                let decision = try sut.experiment(experimentKey: 10, user: HackleUser.builder().build())

                expect(decision.variation).to(equal("B"))
                expect(decision.reason).to(equal(DecisionReason.TRAFFIC_ALLOCATED))
                verify(exactly: 1) {
                    eventProcessor.processMock
                }
            }
        }

        describe("experiments (bulk)") {
            it("returns empty when workspace evaluation is absent") {
                fetcher.returns = nil
                expect(try sut.experiments(user: HackleUser.builder().build()).count).to(equal(0))
            }

            it("evaluates all results with record=false") {
                let workspace = MockWorkspaceEvaluation()
                workspace.experimentResults = [
                    experimentRemoteResult(id: 1, key: 10),
                    experimentRemoteResult(id: 2, key: 20)
                ]
                fetcher.returns = workspace

                let decisions = try sut.experiments(user: HackleUser.builder().build())

                expect(decisions.count).to(equal(2))
                verify(exactly: 0) {
                    eventProcessor.processMock
                }
            }
        }

        describe("featureFlag") {
            it("SDK_NOT_READY off when workspace evaluation is absent") {
                fetcher.returns = nil
                let decision = try sut.featureFlag(featureKey: 10, user: HackleUser.builder().build())
                expect(decision.isOn).to(beFalse())
                expect(decision.reason).to(equal(DecisionReason.SDK_NOT_READY))
            }

            it("FEATURE_FLAG_NOT_FOUND when key is not evaluated") {
                fetcher.returns = MockWorkspaceEvaluation()
                let decision = try sut.featureFlag(featureKey: 10, user: HackleUser.builder().build())
                expect(decision.reason).to(equal(DecisionReason.FEATURE_FLAG_NOT_FOUND))
            }

            it("returns on when server-evaluated variation is not A") {
                let workspace = MockWorkspaceEvaluation()
                workspace.featureFlagResults = [experimentRemoteResult(id: 1, key: 10, type: .featureFlag)]   // variation "B"
                fetcher.returns = workspace

                let decision = try sut.featureFlag(featureKey: 10, user: HackleUser.builder().build())

                expect(decision.isOn).to(beTrue())
                verify(exactly: 1) {
                    eventProcessor.processMock
                }
            }
        }

        describe("featureFlags (bulk)") {
            it("returns empty when workspace evaluation is absent") {
                fetcher.returns = nil
                expect(try sut.featureFlags(user: HackleUser.builder().build()).count).to(equal(0))
            }

            it("evaluates all results with record=false") {
                let workspace = MockWorkspaceEvaluation()
                workspace.featureFlagResults = [
                    experimentRemoteResult(id: 1, key: 10, type: .featureFlag),
                    experimentRemoteResult(id: 2, key: 20, type: .featureFlag)
                ]
                fetcher.returns = workspace

                let decisions = try sut.featureFlags(user: HackleUser.builder().build())

                expect(decisions.count).to(equal(2))
                verify(exactly: 0) {
                    eventProcessor.processMock
                }
            }
        }

        describe("remoteConfig") {
            it("SDK_NOT_READY with default value when workspace evaluation is absent") {
                fetcher.returns = nil
                let decision = try sut.remoteConfig(parameterKey: "rc_key", user: HackleUser.builder().build(), defaultValue: HackleValue(value: "default"))
                expect(decision.value.stringOrNil).to(equal("default"))
                expect(decision.reason).to(equal(DecisionReason.SDK_NOT_READY))
            }

            it("REMOTE_CONFIG_PARAMETER_NOT_FOUND when key is not evaluated") {
                fetcher.returns = MockWorkspaceEvaluation()
                let decision = try sut.remoteConfig(parameterKey: "rc_key", user: HackleUser.builder().build(), defaultValue: HackleValue(value: "default"))
                expect(decision.reason).to(equal(DecisionReason.REMOTE_CONFIG_PARAMETER_NOT_FOUND))
            }

            it("returns server-evaluated value") {
                let workspace = MockWorkspaceEvaluation()
                workspace.remoteConfigParameterResults = [remoteConfigRemoteResult(key: "rc_key", value: RemoteConfigParameterEntity.Value(id: 7, rawValue: HackleValue(value: "v")), reason: DecisionReason.TARGET_RULE_MATCH)]
                fetcher.returns = workspace

                let decision = try sut.remoteConfig(parameterKey: "rc_key", user: HackleUser.builder().build(), defaultValue: HackleValue(value: "default"))

                expect(decision.value.stringOrNil).to(equal("v"))
                expect(decision.reason).to(equal(DecisionReason.TARGET_RULE_MATCH))
            }
        }
    }
}
