import Foundation
import Quick
import Nimble
@testable import Hackle


class InAppMessageEventProcessorSpecs: QuickSpec {
    override func spec() {

        describe("InAppMessageEventProcessorFactory") {

            it("when processor is empty then returns nil") {
                expect(InAppMessageEventProcessorFactory(processors: []).get(event: .impression)).to(beNil())
            }

            it("when all processors not support then returns nil") {
                let sut = InAppMessageEventProcessorFactory(processors: [
                    MockInAppMessageEventProcessor(false),
                    MockInAppMessageEventProcessor(false),
                    MockInAppMessageEventProcessor(false),
                    MockInAppMessageEventProcessor(false)
                ])
                expect(sut.get(event: .impression)).to(beNil())
            }

            it("returns first supports processor") {
                let processor = MockInAppMessageEventProcessor(true)
                let sut = InAppMessageEventProcessorFactory(processors: [
                    MockInAppMessageEventProcessor(false),
                    MockInAppMessageEventProcessor(false),
                    processor,
                    MockInAppMessageEventProcessor(true)
                ])
                expect(sut.get(event: .impression)).to(beIdenticalTo(processor))
            }
        }

        describe("InAppMessageImpressionEventProcessor") {

            var sut: InAppMessageImpressionEventProcessor!

            beforeEach {
                sut = InAppMessageImpressionEventProcessor()
            }
            it("supports") {
                expect(sut.supports(event: .impression)) == true
                expect(sut.supports(event: .close)) == false
            }

            it("process") {
                let view = MockInAppMessageView(presented: true)
                sut.process(view: view, event: .impression, user: HackleUser.builder().build(), timestamp: Date())
            }
        }

        describe("InAppMessageActionEventProcessor") {

            var actionHandler: MockInAppMessageActionHandler!
            var actionHandlerFactory: InAppMessageActionHandlerFactory!
            var sut: InAppMessageActionEventProcessor!

            beforeEach {
                actionHandler = MockInAppMessageActionHandler()
                actionHandlerFactory = InAppMessageActionHandlerFactory(handlers: [actionHandler])
                sut = InAppMessageActionEventProcessor(actionHandlerFactory: actionHandlerFactory)
            }

            it("supports") {
                expect(sut.supports(event: .action(InAppMessage.action(), .button))) == true
                expect(sut.supports(event: .impression)) == false
                expect(sut.supports(event: .close)) == false
            }

            it("when not action event then do nothing") {
                // given
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.impression

                // when
                sut.process(view: view, event: event, user: HackleUser.builder().build(), timestamp: Date())

                // then
                verify(exactly: 0) {
                    actionHandler.handleMock
                }
            }

            it("when cannot found action handler then do nothing") {
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.action(InAppMessage.action(), .button)
                actionHandler.supportsReturn = false

                // when
                sut.process(view: view, event: event, user: HackleUser.builder().build(), timestamp: Date())

                // then
                verify(exactly: 0) {
                    actionHandler.handleMock
                }
            }

            it("handle action") {
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.action(InAppMessage.action(), .button)

                // when
                sut.process(view: view, event: event, user: HackleUser.builder().build(), timestamp: Date())

                // then
                verify(exactly: 1) {
                    actionHandler.handleMock
                }
            }
        }

        describe("InAppMessageCloseEventProcessor") {
            var sut: InAppMessageCloseEventProcessor!

            beforeEach {
                sut = InAppMessageCloseEventProcessor()
            }

            it("supports") {
                expect(sut.supports(event: .action(InAppMessage.action(), .button))) == false
                expect(sut.supports(event: .impression)) == false
                expect(sut.supports(event: .close)) == true
            }

            it("dismiss view") {
                let view = MockInAppMessageView(presented: true)
                sut.process(view: view, event: .close, user: HackleUser.builder().build(), timestamp: Date())
                expect(view.presented) == false
            }
        }
    }
}