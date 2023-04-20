//
//  HackleCoreSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class HackleCoreSpecs: QuickSpec {
    override func spec() {

        /*
         *       RC(1)
         *      /     \
         *     /       \
         *  AB(2)     FF(4)
         *    |   \     |
         *    |     \   |
         *  AB(3)     FF(5)
         *              |
         *              |
         *            AB(6)
         */
        it("target_experiment") {
            let workspaceFetcher = ResourcesWorkspaceFetcher(fileName: "target_experiment")
            let eventProcessor = InMemoryUserEventProcessor()
            let core = DefaultHackleCore.create(workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor, manualOverrideStorage: DelegatingManualOverrideStorage(storages: []))

            let user = HackleUser.builder().identifier(.id, "user").build()
            let decision = try core.remoteConfig(parameterKey: "rc", user: user, defaultValue: .string("42"))

            expect(decision.value) == .string("Targeting!!")
            expect(decision.reason) == DecisionReason.TARGET_RULE_MATCH
            expect(eventProcessor.processedEvents.count) == 6

            let rc = eventProcessor.processedEvents.first as! UserEvents.RemoteConfig
            expect(rc.properties.count) == 5
            expect(rc.properties["requestValueType"] as! String) == "STRING"
            expect(rc.properties["requestDefaultValue"] as! String) == "42"
            expect(rc.properties["targetRuleKey"] as! String) == "rc_1_key"
            expect(rc.properties["targetRuleName"] as! String) == "rc_1_name"
            expect(rc.properties["returnValue"] as! String) == "Targeting!!"

            for event in eventProcessor.processedEvents.dropFirst() {
                expect(event).to(beAnInstanceOf(UserEvents.Exposure.self))
                let event = event as! UserEvents.Exposure
                expect(event.properties["$targetingRootType"] as! String) == "REMOTE_CONFIG"
                expect(event.properties["$targetingRootId"] as! Int64) == 1
            }
        }

        /*
         *     RC(1)
         *      ↓
         * ┌── AB(2)
         * ↑    ↓
         * |   FF(3)
         * ↑    ↓
         * |   AB(4)
         * └────┘
         */
        it("target_experiment_circular") {
            let workspaceFetcher = ResourcesWorkspaceFetcher(fileName: "target_experiment_circular")
            let eventProcessor = InMemoryUserEventProcessor()
            let core = DefaultHackleCore.create(workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor, manualOverrideStorage: DelegatingManualOverrideStorage(storages: []))

            let user = HackleUser.builder().identifier(.id, "user").build()
            expect(try core.remoteConfig(parameterKey: "rc", user: user, defaultValue: .string("42")))
                .to(throwError())
        }

        /*
         *                     Container(1)
         * ┌──────────────┬───────────────────────────────────────┐
         * | ┌──────────┐ |                                       |
         * | |   AB(2)  | |                                       |
         * | └──────────┘ |                                       |
         * └──────────────┴───────────────────────────────────────┘
         *       25 %                        75 %
         */
        it("container") {
            let workspaceFetcher = ResourcesWorkspaceFetcher(fileName: "container")
            let eventProcessor = InMemoryUserEventProcessor()
            let core = DefaultHackleCore.create(workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor, manualOverrideStorage: DelegatingManualOverrideStorage(storages: []))

            var decisions: [Decision] = []
            for _ in (1...10000) {
                let user = HackleUser.builder().identifier(.id, UUID().uuidString).build()
                let decision = try core.experiment(experimentKey: 2, user: user, defaultVariationKey: "A")
                decisions.append(decision)
            }
            expect(eventProcessor.processedEvents.count) == 10000
            expect(decisions.count) == 10000
            expect(decisions.filter { it in
                    it.reason == DecisionReason.TRAFFIC_ALLOCATED
                }
                .count)
                .to(beGreaterThan(2400))
                .to(beLessThan(2600))
            expect(decisions.filter { it in
                    it.reason == DecisionReason.NOT_IN_MUTUAL_EXCLUSION_EXPERIMENT
                }
                .count)
                .to(beGreaterThan(7400))
                .to(beLessThan(7600))
        }
    }
}