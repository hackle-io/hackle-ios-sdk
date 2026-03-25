import Foundation
@testable import Hackle
import Nimble
import Quick

class DefaultInAppMessageActionHandlerFactorySpecs: QuickSpec {
    override func spec() {
        it("get") {
            let handler1 = MockInAppMessageActionHandler()
            every(handler1.supportsMock).returns(false)
            
            let handler2 = MockInAppMessageActionHandler()
            every(handler2.supportsMock).returns(true)
            
            expect(DefaultInAppMessageActionHandlerFactory(handlers: [handler1, handler2]).get(action: InAppMessage.action())).to(beIdenticalTo(handler2))
            
            expect(DefaultInAppMessageActionHandlerFactory(handlers: [handler1]).get(action: InAppMessage.action())).to(beNil())
        }
    }
}
