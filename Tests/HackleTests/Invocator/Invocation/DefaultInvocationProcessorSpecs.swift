import Foundation
@testable import Hackle
import MockingKit
import Nimble
import Quick

class DefaultInvocationProcessorSpecs: QuickSpec {
    override class func spec() {
        var handler: MockInvocationHandler!
        var handlerFactory: MockInvocationHandlerFactory!
        var sut: DefaultInvocationProcessor!
        
        beforeEach {
            handler = MockInvocationHandler()
            handlerFactory = MockInvocationHandlerFactory(handler: handler)
            sut = DefaultInvocationProcessor(handlerFactory: handlerFactory)
            
            every(handler.invokeMock).returns(.success())
        }
        
        it("process request with handler") {
            // given
            let request = InvocationRequest(command: .getSessionId, parameters: [:], browserProperties: [:])
            
            // when
            let actual = sut.process(request: request)
            
            // then
            expect(actual.isSuccess).to(equal(true))
        }
        
        it("when failed to process invocation then returns failed response") {
            // given
            let request = InvocationRequest(command: .getSessionId, parameters: [:], browserProperties: [:])
            every(handler.invokeMock).returns(.error(error: HackleError.error("failed")))
            
            // when
            let actual = sut.process(request: request)
            
            // then
            expect(actual.isSuccess).to(equal(false))
            expect(actual.message).to(contain("failed"))
        }
    }
}
