import Foundation
@testable import Hackle
import MockingKit

class MockInAppMessageActionHandlerFactory: Mock, InAppMessageActionHandlerFactory {
    lazy var getMock = MockFunction(self, get)
    func get(action: InAppMessage.Action) -> InAppMessageActionHandler? {
        return call(getMock, args: action)
    }
}
