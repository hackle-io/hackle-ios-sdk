//
//  DefaultUserEventFactorySpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class DefaultUserEventFactorySpecs: QuickSpec {
    override class func spec() {

        it("create") {
            let sut = EvaluationEventFactory(clock: ClockStub())

            let evaluation1 = ExperimentEvaluation(
                entity: experiment(id: 1),
                result: ExperimentEvaluateResult(reason: DecisionReason.TRAFFIC_ALLOCATED, variationId: 42, variationKey: "B", config: ParameterConfigurationEntity(id: 42, parameters: [:]))
            )

            let evaluation2 = ExperimentEvaluation(
                entity: experiment(id: 2, type: .featureFlag, version: 2, executionVersion: 3),
                result: ExperimentEvaluateResult(reason: DecisionReason.DEFAULT_RULE, variationId: 320, variationKey: "A", config: nil)
            )

            let request = remoteConfigRequest()
            let rcEvaluation = RemoteConfigEvaluation(
                entity: request.parameter,
                result: RemoteConfigEvaluateResult(reason: DecisionReason.TARGET_RULE_MATCH, value: .string("RC"), valueId: 999),
                properties: PropertiesBuilder().add("returnValue", "RC").build()
            )
            let response = RemoteConfigEvaluateResponse(
                user: request.user,
                workspace: request.workspace,
                evaluation: rcEvaluation,
                references: [evaluation1, evaluation2]
            )

            let events = sut.create(response: response)

            expect(events.count) == 3

            expect(events[0]).to(beAnInstanceOf(UserEvents.RemoteConfig.self))
            let rc = events[0] as! UserEvents.RemoteConfig
            expect(rc.timestamp) == Date(timeIntervalSince1970: 42)
            expect(rc.user).to(beIdenticalTo(request.user))
            expect(rc.parameter).to(beIdenticalTo(request.parameter))
            expect(rc.valueId) == 999
            expect(rc.decisionReason) == DecisionReason.TARGET_RULE_MATCH
            expect(rc.properties["returnValue"] as? String) == "RC"

            expect(events[1]).to(beAnInstanceOf(UserEvents.Exposure.self))
            let exposure1 = events[1] as! UserEvents.Exposure
            expect(exposure1.timestamp) == Date(timeIntervalSince1970: 42)
            expect(exposure1.user).to(beIdenticalTo(request.user))
            expect(exposure1.experiment as? ExperimentEntity).to(beIdenticalTo(evaluation1.experiment as? ExperimentEntity))
            expect(exposure1.variationId) == 42
            expect(exposure1.variationKey) == "B"
            expect(exposure1.decisionReason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(exposure1.properties["$targetingRootType"] as? String) == "REMOTE_CONFIG"
            expect(exposure1.properties["$targetingRootId"] as? Int64) == 1
            expect(exposure1.properties["$parameterConfigurationId"] as? Int64) == 42
            expect(exposure1.properties["$experiment_version"] as? Int) == 1
            expect(exposure1.properties["$execution_version"] as? Int) == 1

            expect(events[2]).to(beAnInstanceOf(UserEvents.Exposure.self))
            let exposure2 = events[2] as! UserEvents.Exposure
            expect(exposure2.timestamp) == Date(timeIntervalSince1970: 42)
            expect(exposure2.user).to(beIdenticalTo(request.user))
            expect(exposure2.experiment as? ExperimentEntity).to(beIdenticalTo(evaluation2.experiment as? ExperimentEntity))
            expect(exposure2.variationId) == 320
            expect(exposure2.variationKey) == "A"
            expect(exposure2.decisionReason) == DecisionReason.DEFAULT_RULE
            expect(exposure2.properties["$targetingRootType"] as? String) == "REMOTE_CONFIG"
            expect(exposure2.properties["$targetingRootId"] as? Int64) == 1
            expect(exposure2.properties["$experiment_version"] as? Int) == 2
            expect(exposure2.properties["$execution_version"] as? Int) == 3
        }

        it("create in-app message events") {
            let sut = EvaluationEventFactory(clock: ClockStub())

            let evaluation1 = experimentEvaluation(reason: DecisionReason.TRAFFIC_ALLOCATED, experiment: experiment(id: 1), variationId: 42, variationKey: "B")

            let request = InAppMessage.eligibilityRequest()
            let eligibilityEvaluation = InAppMessageEligibilityEvaluation(
                entity: request.inAppMessage,
                result: InAppMessageEligibilityEvaluateResult(reason: DecisionReason.IN_APP_MESSAGE_TARGET, isEligible: true)
            )
            let response = InAppMessageEligibilityEvaluateResponse(
                user: request.user,
                workspace: request.workspace,
                evaluation: eligibilityEvaluation,
                references: [evaluation1],
                layout: nil
            )

            let events = sut.create(response: response)

            expect(events.count).to(equal(1))

            expect(events[0]).to(beAnInstanceOf(UserEvents.Exposure.self))
            let exposure1 = events[0] as! UserEvents.Exposure
            expect(exposure1.timestamp) == Date(timeIntervalSince1970: 42)
            expect(exposure1.user).to(beIdenticalTo(request.user))
            expect(exposure1.experiment as? ExperimentEntity).to(beIdenticalTo(evaluation1.experiment as? ExperimentEntity))
            expect(exposure1.variationId) == 42
            expect(exposure1.variationKey) == "B"
            expect(exposure1.decisionReason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(exposure1.properties["$targetingRootType"] as? String) == "IN_APP_MESSAGE"
            expect(exposure1.properties["$targetingRootId"] as? Int64) == 1
            expect(exposure1.properties["$experiment_version"] as? Int) == 1
            expect(exposure1.properties["$execution_version"] as? Int) == 1
        }
    }

    class ClockStub: Clock {
        func now() -> Date {
            Date(timeIntervalSince1970: 42)
        }

        func currentMillis() -> Int64 {
            42
        }

        func tick() -> UInt64 {
            42
        }
    }
}
