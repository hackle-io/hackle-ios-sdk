import Foundation
@testable import Hackle
import MockingKit

class MockInAppMessageEventTracker: Mock, InAppMessageEventTracker {
    lazy var trackMock = MockFunction(self, track)
    func track(context: InAppMessagePresentationContext, event: InAppMessageViewEvent) {
        return call(trackMock, args: (context, event))
    }
}
