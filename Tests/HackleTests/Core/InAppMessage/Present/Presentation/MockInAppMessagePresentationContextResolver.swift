import Foundation
import Mockery
@testable import Hackle

class MockInAppMessagePresentationContextResolver: Mock, InAppMessagePresentationContextResolver {
    lazy var resolveMock = MockFunction.throwable(self, resolve)

    func resolve(requset: InAppMessagePresentRequest) throws -> InAppMessagePresentationContext {
        return try call(resolveMock, args: requset)
    }
}
