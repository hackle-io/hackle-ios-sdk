import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class OperatorMatcherSpecs: QuickSpec {
    override func spec() {

        describe("InMatcher") {

            let sut = InMatcher()

            it("string") {
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "abc"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "abc1"))
            }

            it("number") {
                self.assertTrue(sut.matches(userValue: 320, matchValue: 320))
                self.assertTrue(sut.matches(userValue: 320.0, matchValue: 320))
                self.assertTrue(sut.matches(userValue: 320.0, matchValue: 320.0))
                self.assertFalse(sut.matches(userValue: 321.0, matchValue: 320.0))
            }

            it("boolean") {
                self.assertTrue(sut.matches(userValue: true, matchValue: true))
                self.assertTrue(sut.matches(userValue: false, matchValue: false))
                self.assertFalse(sut.matches(userValue: true, matchValue: false))
                self.assertFalse(sut.matches(userValue: false, matchValue: true))
            }

            it("version") {
                self.assertTrue(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("1.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("2.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("2.0.0"), matchValue: self.v("1.0.0")))
            }
        }

        describe("ContainsMatcher") {
            let sut = ContainsMatcher()

            it("string") {
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "abc"))
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "a"))
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "b"))
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "c"))
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "ab"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ac"))
                self.assertFalse(sut.matches(userValue: "a", matchValue: "ab"))
            }

            it("number") {
                self.assertFalse(sut.matches(userValue: 1, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 11, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 1, matchValue: 11))
            }

            it("boolean") {
                self.assertFalse(sut.matches(userValue: true, matchValue: true))
                self.assertFalse(sut.matches(userValue: false, matchValue: false))
                self.assertFalse(sut.matches(userValue: true, matchValue: false))
                self.assertFalse(sut.matches(userValue: false, matchValue: true))
            }

            it("version") {
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("1.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("2.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("2.0.0"), matchValue: self.v("1.0.0")))
            }
        }

        describe("StartsWithMatcher") {
            let sut = StartsWithMatcher()

            it("string") {
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "abc"))
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "a"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "b"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "c"))
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "ab"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ac"))
                self.assertFalse(sut.matches(userValue: "a", matchValue: "ab"))
            }

            it("number") {
                self.assertFalse(sut.matches(userValue: 1, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 11, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 1, matchValue: 11))
            }

            it("boolean") {
                self.assertFalse(sut.matches(userValue: true, matchValue: true))
                self.assertFalse(sut.matches(userValue: false, matchValue: false))
                self.assertFalse(sut.matches(userValue: true, matchValue: false))
                self.assertFalse(sut.matches(userValue: false, matchValue: true))
            }

            it("version") {
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("1.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("2.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("2.0.0"), matchValue: self.v("1.0.0")))
            }
        }

        describe("EndsWithMatcher") {
            let sut = EndsWithMatcher()

            it("string") {
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "abc"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "a"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "b"))
                self.assertTrue(sut.matches(userValue: "abc", matchValue: "c"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ab"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ac"))
                self.assertFalse(sut.matches(userValue: "a", matchValue: "ab"))
            }

            it("number") {
                self.assertFalse(sut.matches(userValue: 1, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 11, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 1, matchValue: 11))
            }

            it("boolean") {
                self.assertFalse(sut.matches(userValue: true, matchValue: true))
                self.assertFalse(sut.matches(userValue: false, matchValue: false))
                self.assertFalse(sut.matches(userValue: true, matchValue: false))
                self.assertFalse(sut.matches(userValue: false, matchValue: true))
            }

            it("version") {
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("1.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("2.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("2.0.0"), matchValue: self.v("1.0.0")))
            }
        }

        describe("GreaterThanMatcher") {
            let sut = GreaterThanMatcher()

            it("string") {
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "abc"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "a"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "b"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "c"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ab"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ac"))
                self.assertFalse(sut.matches(userValue: "a", matchValue: "ab"))
            }

            it("number") {
                self.assertFalse(sut.matches(userValue: 1, matchValue: 1))
                self.assertTrue(sut.matches(userValue: 1.1, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 1, matchValue: 1.1))
            }

            it("boolean") {
                self.assertFalse(sut.matches(userValue: true, matchValue: true))
                self.assertFalse(sut.matches(userValue: false, matchValue: false))
                self.assertFalse(sut.matches(userValue: true, matchValue: false))
                self.assertFalse(sut.matches(userValue: false, matchValue: true))
            }

            it("version") {
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("1.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("2.0.0")))
                self.assertTrue(sut.matches(userValue: self.v("2.0.0"), matchValue: self.v("1.0.0")))
            }
        }

        describe("GreaterThanOrEqualToMatcher") {
            let sut = GreaterThanOrEqualToMatcher()

            it("string") {
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "abc"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "a"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "b"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "c"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ab"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ac"))
                self.assertFalse(sut.matches(userValue: "a", matchValue: "ab"))
            }

            it("number") {
                self.assertTrue(sut.matches(userValue: 1, matchValue: 1))
                self.assertTrue(sut.matches(userValue: 1.1, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 1, matchValue: 1.1))
            }

            it("boolean") {
                self.assertFalse(sut.matches(userValue: true, matchValue: true))
                self.assertFalse(sut.matches(userValue: false, matchValue: false))
                self.assertFalse(sut.matches(userValue: true, matchValue: false))
                self.assertFalse(sut.matches(userValue: false, matchValue: true))
            }

            it("version") {
                self.assertTrue(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("1.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("2.0.0")))
                self.assertTrue(sut.matches(userValue: self.v("2.0.0"), matchValue: self.v("1.0.0")))
            }
        }

        describe("LessThanMatcher") {
            let sut = LessThanMatcher()

            it("string") {
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "abc"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "a"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "b"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "c"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ab"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ac"))
                self.assertFalse(sut.matches(userValue: "a", matchValue: "ab"))
            }

            it("number") {
                self.assertFalse(sut.matches(userValue: 1, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 1.1, matchValue: 1))
                self.assertTrue(sut.matches(userValue: 1, matchValue: 1.1))
            }

            it("boolean") {
                self.assertFalse(sut.matches(userValue: true, matchValue: true))
                self.assertFalse(sut.matches(userValue: false, matchValue: false))
                self.assertFalse(sut.matches(userValue: true, matchValue: false))
                self.assertFalse(sut.matches(userValue: false, matchValue: true))
            }

            it("version") {
                self.assertFalse(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("1.0.0")))
                self.assertTrue(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("2.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("2.0.0"), matchValue: self.v("1.0.0")))
            }
        }

        describe("LessThanOrEqualToMatcher") {
            let sut = LessThanOrEqualToMatcher()

            it("string") {
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "abc"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "a"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "b"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "c"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ab"))
                self.assertFalse(sut.matches(userValue: "abc", matchValue: "ac"))
                self.assertFalse(sut.matches(userValue: "a", matchValue: "ab"))
            }

            it("number") {
                self.assertTrue(sut.matches(userValue: 1, matchValue: 1))
                self.assertFalse(sut.matches(userValue: 1.1, matchValue: 1))
                self.assertTrue(sut.matches(userValue: 1, matchValue: 1.1))
            }

            it("boolean") {
                self.assertFalse(sut.matches(userValue: true, matchValue: true))
                self.assertFalse(sut.matches(userValue: false, matchValue: false))
                self.assertFalse(sut.matches(userValue: true, matchValue: false))
                self.assertFalse(sut.matches(userValue: false, matchValue: true))
            }

            it("version") {
                self.assertTrue(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("1.0.0")))
                self.assertTrue(sut.matches(userValue: self.v("1.0.0"), matchValue: self.v("2.0.0")))
                self.assertFalse(sut.matches(userValue: self.v("2.0.0"), matchValue: self.v("1.0.0")))
            }
        }
    }

    private func assertTrue(_ actual: Bool) {
        expect(actual).to(beTrue())
    }

    private func assertFalse(_ actual: Bool) {
        expect(actual).to(beFalse())
    }

    private func v(_ version: String) -> Version {
        Version.tryParse(value: version)!
    }
}