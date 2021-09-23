import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultConditionMatcherFactorySpecs: QuickSpec {
    override func spec() {
        let sut = DefaultConditionMatcherFactory()
        it("getMatcher") {
            expect(sut.getMatcher(.userProperty)).to(beAnInstanceOf(PropertyConditionMatcher.self))
            expect(sut.getMatcher(.hackleProperty)).to(beAnInstanceOf(PropertyConditionMatcher.self))
        }
    }
}