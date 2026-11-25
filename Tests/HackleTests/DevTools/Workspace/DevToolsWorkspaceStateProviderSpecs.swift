import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class DevToolsWorkspaceStateProviderSpecs: QuickSpec {
    override class func spec() {

        it("reports abTests and featureFlags from the decision processor") {
            let decisionProcessor = DevToolsDecisionProcessorStub()
            let workspaceManager = MockWorkspaceManager()
            every(workspaceManager.workspaceMock).returns(MockWorkspace())
            let sut = DevToolsWorkspaceStateProvider(
                userManager: MockUserManager(),
                pushTokenManager: MockPushTokenManager(),
                decisionProcessor: decisionProcessor,
                devToolsDecisionProcessor: decisionProcessor,
                abTestOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                workspaceManager: workspaceManager,
                evaluationMode: .local,
                clock: FixedClock(date: Date(timeIntervalSince1970: 42))
            )
            decisionProcessor.experiments = [(experiment(id: 1001, key: 42, name: "홈 배너 실험", type: .abTest, status: .running), Decision.of(experiment: nil, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED))]
            decisionProcessor.featureFlags = [(experiment(id: 2001, key: 7, name: "신규 결제", type: .featureFlag, status: .running), FeatureFlagDecision.on(featureFlag: nil, reason: DecisionReason.DEFAULT_RULE))]
            let state = sut.state()!
            let ab = (state["abTests"] as! [[String: Any]])[0]
            expect(ab["id"]).to(beNil())
            expect(ab["title"] as? String) == "홈 배너 실험"
            expect(ab["key"] as? Int64) == 42
            expect(ab["status"] as? String) == "running"
            expect(ab["variation"] as? String) == "B"
            expect(ab["reason"] as? String) == "TRAFFIC_ALLOCATED"
            let ff = (state["featureFlags"] as! [[String: Any]])[0]
            expect(ff["isOn"] as? Bool) == true
            expect(ff["id"]).to(beNil())
            expect(ff["title"] as? String) == "신규 결제"
        }

        it("reports ab test parameters of the assigned variation") {
            let decisionProcessor = DevToolsDecisionProcessorStub()
            let workspaceManager = MockWorkspaceManager()
            every(workspaceManager.workspaceMock).returns(MockWorkspace())
            let sut = DevToolsWorkspaceStateProvider(
                userManager: MockUserManager(),
                pushTokenManager: MockPushTokenManager(),
                decisionProcessor: decisionProcessor,
                devToolsDecisionProcessor: decisionProcessor,
                abTestOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                workspaceManager: workspaceManager,
                evaluationMode: .local,
                clock: FixedClock(date: Date(timeIntervalSince1970: 42))
            )
            let config = ParameterConfigurationEntity(id: 1, parameters: [
                "button_color": HackleValue(value: "red"),
                "discount": HackleValue(value: 10.0),
                "show_banner": HackleValue(value: false)
            ])
            decisionProcessor.experiments = [
                (experiment(id: 1001, key: 42, type: .abTest, status: .running), Decision.of(experiment: nil, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED, config: config)),
                (experiment(id: 1002, key: 43, type: .abTest, status: .running), Decision.of(experiment: nil, variation: "A", reason: DecisionReason.TRAFFIC_ALLOCATED))
            ]
            let abTests = sut.state()!["abTests"] as! [[String: Any]]
            let parameters = abTests[0]["parameters"] as? [String: Any]
            expect(parameters?["button_color"] as? String) == "red"
            expect(parameters?["discount"] as? Double) == 10.0
            expect(parameters?["show_banner"] as? Bool) == false
            expect((abTests[1]["parameters"] as? [String: Any])?.isEmpty) == true
        }

        it("reports null title when the experiment has no name") {
            let decisionProcessor = DevToolsDecisionProcessorStub()
            let workspaceManager = MockWorkspaceManager()
            every(workspaceManager.workspaceMock).returns(MockWorkspace())
            let sut = DevToolsWorkspaceStateProvider(
                userManager: MockUserManager(),
                pushTokenManager: MockPushTokenManager(),
                decisionProcessor: decisionProcessor,
                devToolsDecisionProcessor: decisionProcessor,
                abTestOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                workspaceManager: workspaceManager,
                evaluationMode: .local,
                clock: FixedClock(date: Date(timeIntervalSince1970: 42))
            )
            decisionProcessor.experiments = [(experiment(id: 1001, key: 42, type: .abTest, status: .running), Decision.of(experiment: nil, variation: "A", reason: DecisionReason.TRAFFIC_ALLOCATED))]
            let ab = (sut.state()!["abTests"] as! [[String: Any]])[0]
            expect(ab["title"] is NSNull) == true
        }

        it("reports feature flag parameters of the current decision") {
            let decisionProcessor = DevToolsDecisionProcessorStub()
            let workspaceManager = MockWorkspaceManager()
            every(workspaceManager.workspaceMock).returns(MockWorkspace())
            let sut = DevToolsWorkspaceStateProvider(
                userManager: MockUserManager(),
                pushTokenManager: MockPushTokenManager(),
                decisionProcessor: decisionProcessor,
                devToolsDecisionProcessor: decisionProcessor,
                abTestOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                workspaceManager: workspaceManager,
                evaluationMode: .local,
                clock: FixedClock(date: Date(timeIntervalSince1970: 42))
            )
            let config = ParameterConfigurationEntity(id: 1, parameters: [
                "title": HackleValue(value: "sale"),
                "count": HackleValue(value: 3.0),
                "enabled": HackleValue(value: true)
            ])
            decisionProcessor.featureFlags = [
                (experiment(id: 2001, key: 7, type: .featureFlag, status: .running), FeatureFlagDecision.on(featureFlag: nil, reason: DecisionReason.DEFAULT_RULE, config: config)),
                (experiment(id: 2002, key: 8, type: .featureFlag, status: .running), FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.FEATURE_FLAG_INACTIVE))
            ]
            let featureFlags = sut.state()!["featureFlags"] as! [[String: Any]]
            let parameters = featureFlags[0]["parameters"] as? [String: Any]
            expect(parameters?["title"] as? String) == "sale"
            expect(parameters?["count"] as? Double) == 3.0
            expect(parameters?["enabled"] as? Bool) == true
            expect((featureFlags[1]["parameters"] as? [String: Any])?.isEmpty) == true
        }
    }
}
