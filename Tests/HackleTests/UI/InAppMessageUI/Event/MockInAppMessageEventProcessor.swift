import Foundation
import MockingKit
@testable import Hackle


class MockInAppMessageEventProcessor: Mock, InAppMessageEventProcessor {

    var supportsReturns = false

    init(_ supportsReturns: Bool = false) {
        self.supportsReturns = supportsReturns
        super.init()
    }

    func supports(event: InAppMessage.Event) -> Bool {
        supportsReturns
    }

    lazy var processMock = MockFunction(self, process)

    func process(view: InAppMessageView, event: InAppMessage.Event, timestamp: Date) {
        call(processMock, args: (view, event, timestamp))
    }
}