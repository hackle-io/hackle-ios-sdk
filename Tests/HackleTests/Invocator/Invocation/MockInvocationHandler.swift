import Foundation
@testable import Hackle
import MockingKit

class MockInvocationHandler: Mock, InvocationHandler {
    typealias T = Void
    
    lazy var invokeMock = MockFunction(self, invoke)
    func invoke(request: InvocationRequest) throws -> InvocationResponse<Void> {
        return call(invokeMock, args: request)
    }
}
