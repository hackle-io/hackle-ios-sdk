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

            describe("process") {
                it("do nothing") {
                    let view = MockInAppMessageView(presented: true)
                    sut.process(view: view, event: .impression, timestamp: Date())
                }
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
                expect(sut.supports(event: .action(action: InAppMessage.action(), area: .button, button: nil, image: nil, imageOrder: nil))) == true
                expect(sut.supports(event: .impression)) == false
                expect(sut.supports(event: .close)) == false
            }

            it("when not action event then do nothing") {
                // given
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.impression

                // when
                sut.process(view: view, event: event, timestamp: Date())

                // then
                verify(exactly: 0) {
                    actionHandler.handleMock
                }
            }

            it("when cannot found action handler then do nothing") {
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.buttonAction(action: InAppMessage.action(), button: InAppMessage.button())
                actionHandler.supportsReturn = false

                // when
                sut.process(view: view, event: event, timestamp: Date())

                // then
                verify(exactly: 0) {
                    actionHandler.handleMock
                }
            }

            it("handle action when view's presented is false") {
                let view = MockInAppMessageView()
                let event = InAppMessage.Event.buttonAction(action: InAppMessage.action(), button: InAppMessage.button())

                // when
                sut.process(view: view, event: event, timestamp: Date())

                // then
                verify(exactly: 0) {
                    actionHandler.handleMock
                }
            }

            it("handle action when view's presented is true") {
                let view = MockInAppMessageView(presented: true)
                let event = InAppMessage.Event.buttonAction(action: InAppMessage.action(), button: InAppMessage.button())

                // when
                sut.process(view: view, event: event, timestamp: Date())

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

                expect(sut.supports(event: .buttonAction(action: InAppMessage.action(), button: InAppMessage.button()))) == false
                expect(sut.supports(event: .impression)) == false
                expect(sut.supports(event: .close)) == true
            }

            it("process do nothing") {
                let view = MockInAppMessageView(presented: true)
                sut.process(view: view, event: .close, timestamp: Date())
            }
        }
    }
}
