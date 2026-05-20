import Foundation
@testable import Hackle
import Nimble
import Quick

class InAppMessageViewEventActionHandlerSpecs: QuickSpec {
    override class func spec() {
        var actor: MockInAppMessageViewEventActor!
        var actorFactory: MockInAppMessageViewEventActorFactory!
        var sut: InAppMessageViewEventActionHandler!

        beforeEach {
            actor = MockInAppMessageViewEventActor()
            actorFactory = MockInAppMessageViewEventActorFactory()
            every(actorFactory.getMock).returns(actor)
            sut = InAppMessageViewEventActionHandler(actorFactory: actorFactory)
        }

        it("supports") {
            for handleType in InAppMessageViewEventHandleType.allCases {
                expect(sut.supports(handleType: handleType)).to(equal(handleType == .action))
            }
        }

        describe("handle") {
            it("when not found actor for event then do nothing") {
                // given
                every(actorFactory.getMock).returns(nil)

                let view = MockInAppMessageView()
                let event = MockInAppMessageViewEvent()

                // when
                MainActor.assumeIsolated {
                    sut.handle(view: view, event: event)
                }

                // then
                verify(exactly: 0) {
                    actor.actionMock
                }
            }

            it("handle with actor") {
                let event = MockInAppMessageViewEvent()

                // when
                MainActor.assumeIsolated {
                    let view = MockInAppMessageView()
                    sut.handle(view: view, event: event)
                }

                // then
                verify(exactly: 1) {
                    actor.actionMock
                }
            }
        }
    }
}
