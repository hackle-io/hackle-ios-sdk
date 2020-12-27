//
// Created by yong on 2020/12/11.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleAppSpec: QuickSpec {
    override func spec() {

        let user = User(id: "test_id")

        var sut: HackleApp!
        var decider: MockDecider!
        var workspaceFetcher: MockWorkspaceFetcher!
        var eventProcessor: MockUserEventProcessor!

        beforeEach {
            decider = MockDecider()
            workspaceFetcher = MockWorkspaceFetcher()
            eventProcessor = MockUserEventProcessor()
            sut = HackleApp(decider: decider, workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor)
        }

        describe("variation") {

            context("Workspace를 가져오지 못하면") {
                beforeEach {
                    every(workspaceFetcher.fetchMock).returns(nil)
                }
                it("defaultVariation을 리턴한다") {
                    let actual = sut.variation(experimentKey: 42, user: user, defaultVariation: "J")
                    expect(actual) == "J"
                }

            }

            context("experimentKey에 해당하는 experiment가 없으면") {
                beforeEach {
                    let workspace = MockWorkspace()
                    every(workspaceFetcher.fetchMock).returns(workspace)
                }
                it("defaultVariation을 리턴한다") {
                    let actual = sut.variation(experimentKey: 42, user: user, defaultVariation: "E")
                    expect(actual) == "E"
                }
            }

            context("실험에 할당 되지 않았으면") {
                beforeEach {
                    let experiment = MockRunning()
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(experiment)
                    every(workspaceFetcher.fetchMock).returns(workspace)
                    every(decider.decideMock).returns(Decision.NotAllocated)
                }

                it("defaultVariation을 리턴한다") {
                    let actual = sut.variation(experimentKey: 42, user: user, defaultVariation: "I")
                    expect(actual) == "I"
                }
            }

            context("강제할당된 경우") {

                let variation = "F"

                beforeEach {
                    let experiment = MockRunning()
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(experiment)
                    every(workspaceFetcher.fetchMock).returns(workspace)
                    every(decider.decideMock).returns(Decision.ForcedAllocated(variationKey: variation))
                }

                it("강제 할당된 Variation을 리턴한다") {
                    let actual = sut.variation(experimentKey: 42, user: user, defaultVariation: "A")
                    expect(actual) == "F"
                }

                it("노출이벤트를 전송하지 않는다") {
                    _ = sut.variation(experimentKey: 42, user: user, defaultVariation: "A")
                    expect(eventProcessor.processMock.wasCalled()) == false
                }
            }

            context("자연 할당된 경우") {
                beforeEach {
                    let variation = MockVariation(key: "E")
                    let experiment = MockRunning()
                    let workspace = MockWorkspace()
                    every(workspace.getExperimentOrNilMock).returns(experiment)
                    every(workspaceFetcher.fetchMock).returns(workspace)
                    every(decider.decideMock).returns(Decision.NaturalAllocated(variation: variation))
                }

                it("할당된 Variation을 리턴한다") {
                    let actual = sut.variation(experimentKey: 42, user: user, defaultVariation: "A")
                    expect(actual) == "E"
                }
                it("노출 이벤트를 전송한다") {
                    _ = sut.variation(experimentKey: 42, user: user, defaultVariation: "A")
                    expect(eventProcessor.processMock.wasCalled(exactly: 1)) == true
                }
            }
        }

        describe("track") {

            context("Workspace를 가져오지 못하면") {
                beforeEach {
                    every(workspaceFetcher.fetchMock).returns(nil)
                }

                it("이벤트를 전송하지 않는다") {
                    sut.track(eventKey: "test_event_key", user: user)
                    expect(eventProcessor.processMock.wasCalled()) == false
                }
            }

            context("eventKey에 대한 eventType을 찾지 못하면") {
                beforeEach {
                    let workspace = MockWorkspace()
                    every(workspaceFetcher.fetchMock).returns(workspace)
                }
                it("Undefined 이벤트를 전송한다") {
                    sut.track(eventKey: "test_key", user: user)
                    expect(eventProcessor.processMock.wasCalled()) == true

                    let inv = eventProcessor.processMock.invokations()
                    let userEvent = inv[0].arguments as! UserEvents.Track
                    expect(userEvent.eventType).to(beAnInstanceOf(UndefinedEventType.self))
                }
            }

            context("eventKey에 대한 evenType이 정의 되어 있으면") {
                let eventType = EventTypeEntity(id: 320, key: "custom_key")

                beforeEach {
                    let workspace = MockWorkspace()
                    every(workspace.getEventTypeOrNilMock).returns(eventType)
                    every(workspaceFetcher.fetchMock).returns(workspace)
                }

                it("정의된 정보로 이벤트를 전송한다") {
                    sut.track(eventKey: "custom_key", user: user)

                    expect(eventProcessor.processMock.wasCalled()) == true
                    let inv = eventProcessor.processMock.invokations()
                    let userEvent = inv[0].arguments as! UserEvents.Track
                    expect(userEvent.eventType.id) == 320
                    expect(userEvent.eventType.key) == "custom_key"
                }
            }
        }

        describe("initialize") {
            it("eventProcessor를 시작한다") {

                // when
                sut.initialize {  }

                // then
                expect(eventProcessor.startMock.wasCalled(exactly: 1)) == true
            }

            it("workspace를 서버에서 가져온다") {

                // when
                sut.initialize {  }

                // then
                expect(workspaceFetcher.fetchFromServerMock.wasCalled(exactly: 1)) == true
            }

            it("workspace를 서버에서 가져온 이후 completion을 호출한다") {

                // given
                var completed = false

                // when
                sut.initialize {
                    completed = true
                }
                workspaceFetcher.fetchFromServerMock.invokations()[0].arguments()

                // then
                expect(completed) == true
            }
        }
    }
}
