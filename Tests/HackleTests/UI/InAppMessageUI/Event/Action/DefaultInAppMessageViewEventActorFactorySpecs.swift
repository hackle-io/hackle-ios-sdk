import Foundation
@testable import Hackle
import Nimble
import Quick

class DefaultInAppMessageViewEventActorFactorySpecs: QuickSpec {
    override class func spec() {
        it("get") {
            let actor1 = MockInAppMessageViewEventActor()
            every(actor1.supportsMock).returns(false)
            
            let actor2 = MockInAppMessageViewEventActor()
            every(actor2.supportsMock).returns(true)
            
            let sut = DefaultInAppMessageViewEventActorFactory(actors: [actor1, actor2])
            
            let actual = sut.get(type: .action)
            expect(actual).to(beIdenticalTo(actor2))
            
            expect(DefaultInAppMessageViewEventActorFactory(actors: [actor1]).get(type: .action)).to(beNil())
         }
    }
}
