//
//  SessionUserDecoratorSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/14/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class SessionUserDecoratorSpecs: QuickSpec {
    override func spec() {
        var sessionManager: MockSessionManager!
        var sut: SessionUserDecorator!

        beforeEach {
            sessionManager = MockSessionManager()
            sut = SessionUserDecorator(sessionManager: sessionManager)
        }

        describe("decorate") {
            context("when user already has sessionId") {
                it("returns user without modification") {
                    // given
                    let user = HackleUser.builder()
                        .identifier(.id, "user-id")
                        .identifier(.session, "existing-session-id")
                        .build()

                    // when
                    let decorated = sut.decorate(user: user)

                    // then
                    expect(decorated.sessionId) == "existing-session-id"
                    expect(decorated.identifiers["$sessionId"] as? String) == "existing-session-id"
                }
            }

            context("when user does not have sessionId") {
                context("when sessionManager has no current session") {
                    it("returns user without adding sessionId") {
                        // given
                        sessionManager.currentSession = nil
                        let user = HackleUser.builder()
                            .identifier(.id, "user-id")
                            .build()

                        // when
                        let decorated = sut.decorate(user: user)

                        // then
                        expect(decorated.sessionId).to(beNil())
                        expect(decorated.identifiers["$sessionId"]).to(beNil())
                    }
                }

                context("when sessionManager has current session") {
                    it("decorates user with session id") {
                        // given
                        let session = Session(id: "session-123")
                        sessionManager.currentSession = session

                        let user = HackleUser.builder()
                            .identifier(.id, "user-id")
                            .identifier(.device, "device-id")
                            .build()

                        // when
                        let decorated = sut.decorate(user: user)

                        // then
                        expect(decorated.sessionId) == "session-123"
                        expect(decorated.identifiers["$sessionId"] as? String) == "session-123"

                        // Verify other identifiers are preserved
                        expect(decorated.id) == "user-id"
                        expect(decorated.deviceId) == "device-id"
                    }

                    it("preserves other user properties") {
                        // given
                        let session = Session(id: "session-456")
                        sessionManager.currentSession = session

                        let user = HackleUser.builder()
                            .identifier(.id, "user-id")
                            .identifier(.user, "userId-123")
                            .property("age", 30)
                            .property("name", "John")
                            .hackleProperty("platform", "iOS")
                            .cohort(Cohort(id: 42))
                            .build()

                        // when
                        let decorated = sut.decorate(user: user)

                        // then
                        expect(decorated.sessionId) == "session-456"
                        expect(decorated.userId) == "userId-123"
                        expect(decorated.properties["age"] as? Int) == 30
                        expect(decorated.properties["name"] as? String) == "John"
                        expect(decorated.hackleProperties["platform"] as? String) == "iOS"
                        expect(decorated.cohorts).to(contain(Cohort(id: 42)))
                    }
                }
            }

            context("overwrite behavior") {
                it("does not overwrite existing sessionId when overwrite is false") {
                    // given
                    let session = Session(id: "new-session-id")
                    sessionManager.currentSession = session

                    let user = HackleUser.builder()
                        .identifier(.id, "user-id")
                        .identifier(.session, "old-session-id")
                        .build()

                    // when
                    let decorated = sut.decorate(user: user)

                    // then
                    expect(decorated.sessionId) == "old-session-id"
                }
            }
        }

        describe("integration with HackleUser extension") {
            it("can be used with decorateWith extension method") {
                // given
                let session = Session(id: "session-ext-123")
                sessionManager.currentSession = session

                let user = HackleUser.builder()
                    .identifier(.id, "user-id")
                    .build()

                // when
                let decorated = user.decorateWith(docorator: sut)

                // then
                expect(decorated.sessionId) == "session-ext-123"
            }
        }
    }
}
