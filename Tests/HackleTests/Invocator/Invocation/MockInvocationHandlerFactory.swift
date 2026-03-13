import Foundation
@testable import Hackle
import MockingKit

class MockInvocationHandlerFactory: Mock, InvocationHandlerFactory {
    var handler: any InvocationHandler
    init(handler: any InvocationHandler) {
        self.handler = handler
    }
    
    func get(command: InvocationCommand) throws -> any InvocationHandler {
        return handler
    }
}
