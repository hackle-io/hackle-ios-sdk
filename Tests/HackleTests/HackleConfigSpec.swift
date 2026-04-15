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
    override class func spec() {

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

        describe("monitoringEnabled") {
            it("default value should be true") {
                let config = HackleConfigBuilder().build()
                expect(config.monitoringEnabled) == true
            }

            it("should be able to set to false") {
                let config = HackleConfigBuilder()
                    .monitoringEnabled(false)
                    .build()
                expect(config.monitoringEnabled) == false
            }

            it("should be able to set to true explicitly") {
                let config = HackleConfigBuilder()
                    .monitoringEnabled(true)
                    .build()
                expect(config.monitoringEnabled) == true
            }

            it("last value should take precedence when called multiple times") {
                let config = HackleConfigBuilder()
                    .monitoringEnabled(false)
                    .monitoringEnabled(true)
                    .build()
                expect(config.monitoringEnabled) == true
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

        describe("sessionPolicy") {
            it("기본값은 default 이다") {
                let config = HackleConfigBuilder().build()
                expect(config.sessionPolicy.persistCondition) === HackleSessionPersistCondition.alwaysNewSession
                expect(config.sessionPolicy.timeoutCondition.timeoutIntervalSeconds) == 1800
                expect(config.sessionPolicy.timeoutCondition.onForeground) == false
                expect(config.sessionPolicy.timeoutCondition.onBackground) == true
                expect(config.sessionPolicy.timeoutCondition.onApplicationStateChange) == true
            }

            it("커스텀 sessionPolicy 설정") {
                let policy = HackleSessionPolicy.builder()
                    .persistCondition(.nullToUserId)
                    .timeoutCondition(
                        HackleSessionTimeoutCondition.builder()
                            .timeoutIntervalSeconds(600)
                            .onForeground(true)
                            .build()
                    )
                    .build()
                let config = HackleConfigBuilder().sessionPolicy(policy).build()
                expect(config.sessionPolicy.persistCondition) === HackleSessionPersistCondition.nullToUserId
                expect(config.sessionPolicy.timeoutCondition.timeoutIntervalSeconds) == 600
                expect(config.sessionPolicy.timeoutCondition.onForeground) == true
            }

            it("deprecated sessionTimeoutIntervalSeconds 설정 시 policy timeout 에 반영된다") {
                let config = HackleConfigBuilder().sessionTimeoutIntervalSeconds(900).build()
                expect(config.sessionPolicy.timeoutCondition.timeoutIntervalSeconds) == 900
            }

            it("sessionPolicy 직접 설정 시 deprecated timeout 설정을 무시한다") {
                let policy = HackleSessionPolicy.builder()
                    .timeoutCondition(
                        HackleSessionTimeoutCondition.builder()
                            .timeoutIntervalSeconds(600)
                            .build()
                    )
                    .build()
                let config = HackleConfigBuilder()
                    .sessionTimeoutIntervalSeconds(900)
                    .sessionPolicy(policy)
                    .build()
                expect(config.sessionPolicy.timeoutCondition.timeoutIntervalSeconds) == 600
            }

            it("아무것도 설정하지 않으면 기본값이다") {
                let config = HackleConfigBuilder().build()
                expect(config.sessionPolicy.timeoutCondition.timeoutIntervalSeconds) == 1800
                expect(config.sessionPolicy.persistCondition) === HackleSessionPersistCondition.alwaysNewSession
            }

            it("deprecated sessionTimeoutIntervalSeconds 설정 시 기존 persistCondition 을 유지한다") {
                let config = HackleConfigBuilder()
                    .sessionPolicy(
                        HackleSessionPolicy.builder()
                            .persistCondition(.nullToUserId)
                            .build()
                    )
                    .sessionTimeoutIntervalSeconds(900)
                    .build()
                expect(config.sessionPolicy.persistCondition) === HackleSessionPersistCondition.nullToUserId
                expect(config.sessionPolicy.timeoutCondition.timeoutIntervalSeconds) == 900
            }

            it("sessionTimeoutInterval computed property 는 policy 의 timeout 을 반환한다") {
                let config = HackleConfigBuilder()
                    .sessionPolicy(
                        HackleSessionPolicy.builder()
                            .timeoutCondition(
                                HackleSessionTimeoutCondition.builder()
                                    .timeoutIntervalSeconds(600)
                                    .build()
                            )
                            .build()
                    )
                    .build()
                expect(config.sessionTimeoutInterval) == 600
            }

            it("sessionTimeoutInterval 기본값은 1800초(30분) 이다") {
                let config = HackleConfigBuilder().build()
                expect(config.sessionTimeoutInterval) == 1800
            }

            it("toBuilder 는 모든 필드를 복사한다") {
                let original = HackleSessionPolicy.builder()
                    .persistCondition(.nullToUserId)
                    .timeoutCondition(
                        HackleSessionTimeoutCondition.builder()
                            .timeoutIntervalSeconds(600)
                            .onForeground(true)
                            .onBackground(false)
                            .onApplicationStateChange(false)
                            .build()
                    )
                    .build()

                let copy = original.toBuilder().build()

                expect(copy.persistCondition) === HackleSessionPersistCondition.nullToUserId
                expect(copy.timeoutCondition.timeoutIntervalSeconds) == 600
                expect(copy.timeoutCondition.onForeground) == true
                expect(copy.timeoutCondition.onBackground) == false
                expect(copy.timeoutCondition.onApplicationStateChange) == false
            }

            it("timeout 이 0 이하이면 기본값으로 교체된다") {
                let config = HackleConfigBuilder().sessionTimeoutIntervalSeconds(0).build()
                expect(config.sessionPolicy.timeoutCondition.timeoutIntervalSeconds) == 1800
            }

            it("timeout 이 음수이면 기본값으로 교체된다") {
                let config = HackleConfigBuilder().sessionTimeoutIntervalSeconds(-1).build()
                expect(config.sessionPolicy.timeoutCondition.timeoutIntervalSeconds) == 1800
            }
        }

        describe("HackleSessionPersistCondition") {
            it("기본 구현은 false 를 반환한다") {
                let condition = HackleSessionPersistCondition()
                let user = User.builder().build()
                let result = condition.shouldPersist(oldUser: user, newUser: user)
                expect(result) == false
            }
        }
        describe("optOutTracking") {
            it("default value should be false") {
                let config = HackleConfigBuilder().build()
                expect(config.optOutTracking) == false
            }

            it("should be able to set to true") {
                let config = HackleConfigBuilder()
                    .optOutTracking(true)
                    .build()
                expect(config.optOutTracking) == true
            }

            it("should be able to set to false explicitly") {
                let config = HackleConfigBuilder()
                    .optOutTracking(false)
                    .build()
                expect(config.optOutTracking) == false
            }

            it("last value should take precedence when called multiple times") {
                let config = HackleConfigBuilder()
                    .optOutTracking(true)
                    .optOutTracking(false)
                    .build()
                expect(config.optOutTracking) == false
            }
        }

    }
}
