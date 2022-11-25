import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class ValueMatcherFactorySpecs: QuickSpec {


    override func spec() {

        let sut = ValueMatcherFactory()

        it("getMatcher") {
            expect(sut.getMatcher(.string)).to(beAnInstanceOf(StringMatcher.self))
            expect(sut.getMatcher(.number)).to(beAnInstanceOf(NumberMatcher.self))
            expect(sut.getMatcher(.bool)).to(beAnInstanceOf(BoolMatcher.self))
            expect(sut.getMatcher(.version)).to(beAnInstanceOf(VersionMatcher.self))
            expect(sut.getMatcher(.json)).to(beAnInstanceOf(StringMatcher.self))
            expect(sut.getMatcher(.null)).to(beAnInstanceOf(NoneMatcher.self))
        }
    }
}
