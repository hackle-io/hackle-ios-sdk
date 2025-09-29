import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageIdentifierChecker: Mock, InAppMessageIdentifierChecker {
    lazy var isIdentifierChangedMock = MockFunction(self, isIdentifierChanged)

    func isIdentifierChanged(old: Identifiers, new: Identifiers) -> Bool {
        return call(isIdentifierChangedMock, args: (old, new))
    }
}
