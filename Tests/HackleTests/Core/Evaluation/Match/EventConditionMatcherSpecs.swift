//
//  EventConditionMatcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class EventConditionMatcherSpecs: QuickSpec {
    override func spec() {

        var eventValueResolver: EventValueResolver!
        var valueOperatorMatcher: MockValueOperatorMatcher!
        var sut: EventConditionMatcher!

        beforeEach {
            eventValueResolver = DefaultEventValueResolver()
            valueOperatorMatcher = MockValueOperatorMatcher()
            sut = EventConditionMatcher(eventValueResolver: eventValueResolver, valueOperatorMatcher: valueOperatorMatcher)
        }

        it("when request is not of EvaluatorEventRequest type then returns false") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .eventProperty, name: "os_name"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "iOS")])
            )
            let request = experimentRequest()

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == false
        }

        it("when cannot resolve event value then returns false") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .eventProperty, name: "os_name"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "iOS")])
            )

            let user = HackleUser.builder().identifier(.id, "user").build()
            let event = UserEvents.track(
                eventType: EventTypeEntity(id: 42, key: "test"),
                event: Event.builder("test").build(),
                timestamp: Date(), user: user
            )
            let request = EventRequest(workspace: MockWorkspace(), user: user, event: event)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == false
        }

        it("matches") {
            // given
            let condition = Target.Condition(
                key: Target.Key(type: .eventProperty, name: "os_name"),
                match: Target.Match(type: .match, matchOperator: ._in, valueType: .string, values: [HackleValue(value: "iOS")])
            )

            let user = HackleUser.builder().identifier(.id, "user").build()
            let event = UserEvents.track(
                eventType: EventTypeEntity(id: 42, key: "test"),
                event: Event.builder("test").property("os_name", "iOS").build(),
                timestamp: Date(),
                user: user
            )
            let request = EventRequest(workspace: MockWorkspace(), user: user, event: event)

            every(valueOperatorMatcher.matchesMock).returns(true)

            // when
            let actual = try sut.matches(request: request, context: Evaluators.context(), condition: condition)

            // then
            expect(actual) == true
        }
    }

    private class EventRequest: EvaluatorEventRequest {
        let key: EvaluatorKey
        let workspace: Workspace
        let user: HackleUser
        let event: UserEvent

        init(workspace: Workspace, user: HackleUser, event: UserEvent) {
            self.key = EvaluatorKey(type: .event, id: event.timestamp.epochMillis)
            self.workspace = workspace
            self.user = user
            self.event = event
        }
    }
}


class DefaultEventValueResolverSpecs: QuickSpec {
    override func spec() {
        let sut = DefaultEventValueResolver()

        it("TRACK") {
            let user = HackleUser.builder().identifier(.id, "user").build()
            let event = UserEvents.track(
                eventType: EventTypeEntity(id: 42, key: "test"),
                event: Event.builder("test")
                    .property("os_name", "iOS")
                    .build(),
                timestamp: Date(),
                user: user
            )

            expect(try sut.resolveOrNil(event: event, key: Target.Key(type: .eventProperty, name: "os_name")) as! String) == "iOS"
            expect(try sut.resolveOrNil(event: event, key: Target.Key(type: .eventProperty, name: "app_version"))).to(beNil())
        };

        it("EXPOSURE") {
            let user = HackleUser.builder().identifier(.id, "user").build()
            let event = UserEvents.exposure(user: user, evaluation: experimentEvaluation(), properties: ["a": "b"], timestamp: Date())

            expect(try sut.resolveOrNil(event: event, key: Target.Key(type: .eventProperty, name: "a")) as! String) == "b"
            expect(try sut.resolveOrNil(event: event, key: Target.Key(type: .eventProperty, name: "b"))).to(beNil())
        }

        it("REMOTE_CONFIG") {
            let user = HackleUser.builder().identifier(.id, "user").build()

            let request = remoteConfigRequest()
            let evaluation = RemoteConfigEvaluation.of(
                request: request,
                context: Evaluators.context(),
                valueId: 999,
                value: .string("RC"),
                reason: DecisionReason.TARGET_RULE_MATCH,
                properties: PropertiesBuilder()
            )
            let event = UserEvents.remoteConfig(user: user, evaluation: evaluation, properties: ["a": "b"], timestamp: Date())

            expect(try sut.resolveOrNil(event: event, key: Target.Key(type: .eventProperty, name: "a")) as! String) == "b"
            expect(try sut.resolveOrNil(event: event, key: Target.Key(type: .eventProperty, name: "b"))).to(beNil())
        }

        it("Unsupported type") {

            let user = HackleUser.builder().identifier(.id, "user").build()
            let event = UserEvents.exposure(user: user, evaluation: experimentEvaluation(), properties: ["a": "b"], timestamp: Date())

            func check(type: Target.KeyType) {
                expect(try sut.resolveOrNil(event: event, key: Target.Key(type: type, name: "a")))
                    .to(throwError())
            }

            check(type: .userId)
            check(type: .userProperty)
            check(type: .hackleProperty)
            check(type: .segment)
            check(type: .abTest)
            check(type: .featureFlag)
            check(type: .cohort)
        }
    }
}