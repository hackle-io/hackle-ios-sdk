//
//  HackleConfigSpec.swift
//  HackleTests
//
//  Created by yong on 2022/08/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class HackleConfigSpec: QuickSpec {
    override func spec() {

        it("exposureEventDedupInterval") {
            expect(HackleConfigBuilder().build().exposureEventDedupInterval) == 60
            expect(HackleConfigBuilder().exposureEventDedupIntervalSeconds(0.9999).build().exposureEventDedupInterval) == 60
            expect(HackleConfigBuilder().exposureEventDedupIntervalSeconds(86400.1).build().exposureEventDedupInterval) == 60


            for i in 1...86400 {
                let config = HackleConfigBuilder()
                    .exposureEventDedupIntervalSeconds(Double(i))
                    .build()
                expect(config.exposureEventDedupInterval) == Double(i)
            }
        }

        it("eventFlushInterval") {
            expect(HackleConfigBuilder().build().eventFlushInterval) == 10
            expect(HackleConfigBuilder().eventFlushIntervalSeconds(0.9999).build().eventFlushInterval) == 10
            expect(HackleConfigBuilder().eventFlushIntervalSeconds(60.1).build().eventFlushInterval) == 10


            for i in 1...60 {
                let config = HackleConfigBuilder()
                    .eventFlushIntervalSeconds(Double(i))
                    .build()
                expect(config.eventFlushInterval) == Double(i)
            }
        }

        it("eventFlushThreshold") {
            expect(HackleConfigBuilder().build().eventFlushThreshold) == 10
            expect(HackleConfigBuilder().eventFlushThreshold(4).build().eventFlushThreshold) == 10
            expect(HackleConfigBuilder().eventFlushThreshold(31).build().eventFlushThreshold) == 10


            for i in 5...30 {
                let config = HackleConfigBuilder()
                    .eventFlushThreshold(i)
                    .build()
                expect(config.eventFlushThreshold) == i
            }
        }

        it("extra") {
            let config = HackleConfigBuilder()
                .add("test_key", "test_value")
                .build()
            expect(config.get("test_key")) == "test_value"
            expect(config.get("test_key2")).to(beNil())
        }

        it("mode") {
            expect(HackleConfig.builder().mode(.native).build().sessionTracking).to(be(true))
            expect(HackleConfig.builder().mode(.web_view_wrapper).build().sessionTracking).to(be(false))
        }

        context("HackleAppMode") {
            it("description") {
                expect(HackleAppMode.native.description).to(equal("native"))
                expect(HackleAppMode.web_view_wrapper.description).to(equal("web_view_wrapper"))
            }
        }

        describe("automaticAppLifecycleTracking") {
            it("default value should be true") {
                let config = HackleConfigBuilder().build()
                expect(config.automaticAppLifecycleTracking) == true
            }

            it("should be able to set to false") {
                let config = HackleConfigBuilder()
                    .automaticAppLifecycleTracking(false)
                    .build()
                expect(config.automaticAppLifecycleTracking) == false
            }

            it("should be able to set to true explicitly") {
                let config = HackleConfigBuilder()
                    .automaticAppLifecycleTracking(true)
                    .build()
                expect(config.automaticAppLifecycleTracking) == true
            }

            it("last value should take precedence when called multiple times") {
                let config = HackleConfigBuilder()
                    .automaticAppLifecycleTracking(false)
                    .automaticAppLifecycleTracking(true)
                    .build()
                expect(config.automaticAppLifecycleTracking) == true
            }
        }
    }
}
