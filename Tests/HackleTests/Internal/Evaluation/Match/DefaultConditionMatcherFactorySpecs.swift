import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultConditionMatcherFactorySpecs: QuickSpec {
    override func spec() {
        let sut = DefaultConditionMatcherFactory()
        it("getMatcher") {
            expect(sut.getMatcher(.userId)).to(beAnInstanceOf(UserConditionMatcher.self))
            expect(sut.getMatcher(.userProperty)).to(beAnInstanceOf(UserConditionMatcher.self))
            expect(sut.getMatcher(.hackleProperty)).to(beAnInstanceOf(UserConditionMatcher.self))
            expect(sut.getMatcher(.segment)).to(beAnInstanceOf(SegmentConditionMatcher.self))
        }
    }
}