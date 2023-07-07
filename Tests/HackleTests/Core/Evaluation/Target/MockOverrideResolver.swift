import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockOverrideResolver: Mock, OverrideResolver {

    lazy var resolveOrNilMock = MockFunction(self, resolveOrNil)

    func resolveOrNil(request: ExperimentRequest, context: EvaluatorContext) throws -> Variation? {
        call(resolveOrNilMock, args: (request, context))
    }
}