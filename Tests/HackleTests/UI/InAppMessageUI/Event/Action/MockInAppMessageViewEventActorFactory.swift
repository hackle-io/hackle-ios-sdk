import Foundation
@testable import Hackle
import MockingKit

class MockInAppMessageViewEventActorFactory: Mock, InAppMessageViewEventActorFactory {
    lazy var getMock = MockFunction(self, get)
    func get(type: InAppMessageViewEventType) -> InAppMessageViewEventActor? {
        return call(getMock, args: type)
    }
}
