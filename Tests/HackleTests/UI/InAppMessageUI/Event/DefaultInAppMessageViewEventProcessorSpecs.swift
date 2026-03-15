import Foundation
@testable import Hackle
import Nimble
import Quick

class DefaultInAppMessageViewEventProcessorSpecs: QuickSpec {
    override func spec() {
        it("process") {
            let trackHandler = MockInAppMessageViewEventHandler(handleType: .track)
            let actionHandler = MockInAppMessageViewEventHandler(handleType: .action)

            let sut = DefaultInAppMessageViewEventProcessor(
                handlerFactory: DefaultInAppMessageViewEventHandlerFactory(
                    handlers: [
                        trackHandler,
                        actionHandler,
                    ]
                )
            )

            try MainActor.assumeIsolated {
                try sut.process(view: MockInAppMessageView(), event: .impression(timestamp: Date()), types: [.track, .action])
            }

            verify(exactly: 1) {
                trackHandler.handleMock
            }
            verify(exactly: 1) {
                actionHandler.handleMock
            }
        }

        it("process") {
            let trackHandler = MockInAppMessageViewEventHandler(handleType: .track)
            let actionHandler = MockInAppMessageViewEventHandler(handleType: .action)

            let sut = DefaultInAppMessageViewEventProcessor(
                handlerFactory: DefaultInAppMessageViewEventHandlerFactory(
                    handlers: [
                        actionHandler,
                    ]
                )
            )

            try MainActor.assumeIsolated {
                try sut.process(view: MockInAppMessageView(), event: .impression(timestamp: Date()), types: [.track, .action])
            }

            verify(exactly: 0) {
                trackHandler.handleMock
            }
            verify(exactly: 1) {
                actionHandler.handleMock
            }
        }
    }
}
