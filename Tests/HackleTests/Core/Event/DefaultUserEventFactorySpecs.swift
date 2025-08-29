//
//  DefaultUserEventFactorySpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultUserEventFactorySpecs: QuickSpec {
    override func spec() {

        it("create") {
            let sut = DefaultUserEventFactory(clock: ClockStub())

            let context = Evaluators.context()

            let evaluation1 = ExperimentEvaluation(
                reason: DecisionReason.TRAFFIC_ALLOCATED,
                targetEvaluations: [],
                experiment: experiment(id: 1),
                variationId: 42,
                variationKey: "B",
                config: ParameterConfigurationEntity(id: 42, parameters: [:])
            )

            let evaluation2 = ExperimentEvaluation(
                reason: DecisionReason.DEFAULT_RULE,
                targetEvaluations: [],
                experiment: experiment(id: 2, type: .featureFlag, version: 2, executionVersion: 3),
                variationId: 320,
                variationKey: "A",
                config: nil
            )

            context.add(evaluation1)
            context.add(evaluation2)

            let request = remoteConfigRequest()

            let evaluation = RemoteConfigEvaluation.of(
                request: request,
                context: context,
                valueId: 999,
                value: .string("RC"),
                reason: DecisionReason.TARGET_RULE_MATCH,
                properties: PropertiesBuilder()
            )

            let events = sut.create(request: request, evaluation: evaluation)

            expect(events.count) == 3

            expect(events[0]).to(beAnInstanceOf(UserEvents.RemoteConfig.self))
            let rc = events[0] as! UserEvents.RemoteConfig
            expect(rc.timestamp) == Date(timeIntervalSince1970: 42)
            expect(rc.user).to(beIdenticalTo(request.user))
            expect(rc.parameter).to(beIdenticalTo(request.parameter))
            expect(rc.valueId) == 999
            expect(rc.decisionReason) == DecisionReason.TARGET_RULE_MATCH
            expect(rc.properties.count) == 1
            expect(rc.properties["returnValue"] as? String) == "RC"

            expect(events[1]).to(beAnInstanceOf(UserEvents.Exposure.self))
            let exposure1 = events[1] as! UserEvents.Exposure
            expect(exposure1.timestamp) == Date(timeIntervalSince1970: 42)
            expect(exposure1.user).to(beIdenticalTo(request.user))
            expect(exposure1.experiment).to(beIdenticalTo(evaluation1.experiment))
            expect(exposure1.variationId) == 42
            expect(exposure1.variationKey) == "B"
            expect(exposure1.decisionReason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(exposure1.properties.count) == 5
            expect(exposure1.properties["$targetingRootType"] as? String) == "REMOTE_CONFIG"
            expect(exposure1.properties["$targetingRootId"] as? Int64) == 1
            expect(exposure1.properties["$parameterConfigurationId"] as? Int64) == 42
            expect(exposure1.properties["$experiment_version"] as? Int) == 1
            expect(exposure1.properties["$execution_version"] as? Int) == 1

            expect(events[2]).to(beAnInstanceOf(UserEvents.Exposure.self))
            let exposure2 = events[2] as! UserEvents.Exposure
            expect(exposure2.timestamp) == Date(timeIntervalSince1970: 42)
            expect(exposure2.user).to(beIdenticalTo(request.user))
            expect(exposure2.experiment).to(beIdenticalTo(evaluation2.experiment))
            expect(exposure2.variationId) == 320
            expect(exposure2.variationKey) == "A"
            expect(exposure2.decisionReason) == DecisionReason.DEFAULT_RULE
            expect(exposure2.properties.count) == 4
            expect(exposure2.properties["$targetingRootType"] as? String) == "REMOTE_CONFIG"
            expect(exposure2.properties["$targetingRootId"] as? Int64) == 1
            expect(exposure2.properties["$experiment_version"] as? Int) == 2
            expect(exposure2.properties["$execution_version"] as? Int) == 3
        }

        it("create in-app message events") {
            let sut = DefaultUserEventFactory(clock: ClockStub())

            let context = Evaluators.context()
            let evaluation1 = experimentEvaluation(reason: DecisionReason.TRAFFIC_ALLOCATED, experiment: experiment(id: 1), variationId: 42, variationKey: "B")
            context.add(evaluation1)

            let request = InAppMessage.eligibilityRequest()
            let evaluation = InAppMessageEligibilityEvaluation.of(
                request: request,
                context: context,
                reason: DecisionReason.IN_APP_MESSAGE_TARGET,
                isEligible: true
            )

            let events = sut.create(request: request, evaluation: evaluation)

            expect(events.count).to(equal(1))

            expect(events[0]).to(beAnInstanceOf(UserEvents.Exposure.self))
            let exposure1 = events[0] as! UserEvents.Exposure
            expect(exposure1.timestamp) == Date(timeIntervalSince1970: 42)
            expect(exposure1.user).to(beIdenticalTo(request.user))
            expect(exposure1.experiment).to(beIdenticalTo(evaluation1.experiment))
            expect(exposure1.variationId) == 42
            expect(exposure1.variationKey) == "B"
            expect(exposure1.decisionReason) == DecisionReason.TRAFFIC_ALLOCATED
            expect(exposure1.properties.count) == 4
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
