import Foundation
import Mockery
@testable import Hackle

class MockInAppMessagePresentationContextResolver: Mock, InAppMessagePresentationContextResolver {
    lazy var resolveMock = MockFunction(self, resolve)

    func resolve(requset: InAppMessagePresentRequest) throws -> InAppMessagePresentationContext {
        return call(resolveMock, args: requset)
    }
}
