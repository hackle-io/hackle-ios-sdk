//
// Created by yong on 2020/12/21.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultUserEventDispatcherSpec: QuickSpec {
    override func spec() {

        var httpClient: MockHttpClient!
        var sut: DefaultUserEventDispatcher!

        beforeEach {
            httpClient = MockHttpClient()
            sut = DefaultUserEventDispatcher(eventBaseUrl: URL(string: "localhost")!, httpClient: httpClient)
        }

        describe("dispatch") {

            it("입력된 이벤트로 httpClient 를 호출한다") {
                let events = [UserEvent]()
                sut.dispatch(events: events)

                expect(httpClient.executeMock.wasCalled()).toEventually(equal(true))
            }
        }

        it("UserEvents.Exposure.toDto") {

            let userProperties: [String: Any] = ["age": 20, "grade": "GOLD", "membership": false]
            let user = HackleUser.of(user: Hackle.user(id: "test_id", properties: userProperties), hackleProperties: ["osName": "iOS"])
            let date = Date()
            let experiment = MockExperiment(id: 42, key: 320)
            let variation = MockVariation(id: 142, key: "F")
            let exposure: UserEvents.Exposure = UserEvents.Exposure(
                timestamp: date,
                user: user,
                experiment: experiment,
                variationId: 142,
                variationKey: "F",
                decisionReason: DecisionReason.TRAFFIC_ALLOCATED
            )

            let actual = exposure.toDto()

            expect(actual["timestamp"] as! Int64) == date.epochMillis
            expect(actual["userId"] as! String) == "test_id"
            expect((actual["userProperties"] as! [String: Any])).to(haveCount(3))
            expect((actual["hackleProperties"] as! [String: Any])).to(haveCount(1))
            expect(actual["experimentId"] as! Int64) == 42
            expect(actual["experimentKey"] as! Int64) == 320
            expect(actual["variationId"] as! Int64) == 142
            expect(actual["variationKey"] as! String) == "F"
            expect(actual["decisionReason"] as! String) == "TRAFFIC_ALLOCATED"
        }

        it("UserEvents.Track.toDto") {
            let userProperties: [String: Any] = ["age": 20, "grade": "GOLD", "membership": false]
            let user = HackleUser.of(user: Hackle.user(id: "test_id", properties: userProperties), hackleProperties: ["osName": "iOS"])
            let date = Date()
            let eventType = EventTypeEntity(id: 42, key: "test_event_key")
            let event = Event(key: "test_event_key")

            let dto1 = UserEvents.Track(timestamp: date, user: user, eventType: eventType, event: event).toDto()

            expect(dto1["timestamp"] as! Int64) == date.epochMillis
            expect(dto1["userId"] as! String) == "test_id"
            expect(dto1["userProperties"] as! [String: Any]).to(haveCount(3))
            expect(dto1["hackleProperties"] as! [String: Any]).to(haveCount(1))
            expect(dto1["eventTypeId"] as! Int64) == 42
            expect(dto1["eventTypeKey"] as! String) == "test_event_key"
            expect(dto1["value"]) == nil
            expect(dto1["properties"]) == nil


            let dto2 = UserEvents.Track(
                timestamp: date,
                user: user,
                eventType: eventType,
                event: Event(key: "test_event_key", value: 320.42, properties: ["prop_key_1": "prop_value_1", "prop_key_2": false, "prop_key_3": 42])
            ).toDto()

            expect(dto2["value"] as! Double) == 320.42
            expect(dto2["properties"] as! [String: Any]).to(haveCount(3))
        }
    }
}
