import Foundation
import MockingKit
@testable import Hackle

class MockActionResolver: Mock, ActionResolver {

    lazy var resolveOrNilMock = MockFunction(self, resolveOrNil)

    func resolveOrNil(request: ExperimentLocalEvaluateRequest, action: Action) throws -> Variation? {
        call(resolveOrNilMock, args: (request, action))
    }
}
