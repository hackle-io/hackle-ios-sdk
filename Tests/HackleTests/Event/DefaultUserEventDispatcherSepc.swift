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

            let user = User(id: "test_id")
            let date = Date()
            let experiment = MockRunningExperiment(id: 42, key: 320)
            let variation = MockVariation(id: 142, key: "F")
            let exposure: UserEvents.Exposure = UserEvents.Exposure(user: user, timestamp: date, experiment: experiment, variation: variation)

            let actual = exposure.toDto()

            expect(actual["timestamp"] as! Int64) == date.epochMillis
            expect(actual["userId"] as! String) == "test_id"
            expect(actual["experimentId"] as! Int64) == 42
            expect(actual["experimentKey"] as! Int64) == 320
            expect(actual["variationId"] as! Int64) == 142
            expect(actual["variationKey"] as! String) == "F"
        }

        it("UserEvents.Track.toDto") {
            let user = User(id: "test_id")
            let date = Date()
            let eventType = EventTypeEntity(id: 42, key: "test_event_key")
            let event = Event(key: "test_event_key")

            let dto1 = UserEvents.Track(user: user, timestamp: date, eventType: eventType, event: event).toDto()

            expect(dto1["timestamp"] as! Int64) == date.epochMillis
            expect(dto1["userId"] as! String) == "test_id"
            expect(dto1["eventTypeId"] as! Int64) == 42
            expect(dto1["eventTypeKey"] as! String) == "test_event_key"
            expect(dto1["value"]) == nil
            expect(dto1["properties"]) == nil


            let dto2 = UserEvents.Track(
                user: user,
                timestamp: date,
                eventType: eventType,
                event: Event(key: "test_event_key", value: 320.42, properties: ["prop_key_1": "prop_value_1", "prop_key_2": false])
            ).toDto()

            expect(dto2["value"] as! Double) == 320.42
            expect(dto2["properties"]).toNot(beNil())
        }
    }
}