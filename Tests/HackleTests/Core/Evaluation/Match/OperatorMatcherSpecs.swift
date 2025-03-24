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
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "abc")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "abc"), HackleValue(value: "def")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "abc1")]))
            }

            it("number") {
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320, matchValue: [HackleValue(value: 320)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValue: [HackleValue(value: 320), HackleValue(value: 321)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValue: [HackleValue(value: 320)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValue: [HackleValue(value: 320.0)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 320, matchValue: [HackleValue(value: 321)]))
            }

            it("boolean") {
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: true)]))
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0"), HackleValue(value: "1.0.1")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.1")]))
            }
        }

        describe("ContainsMatcher") {
            let sut = ContainsMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "abc")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "b")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "c")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "ab")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "ac")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "ab")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 11)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValue: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("StartsWithMatcher") {
            let sut = StartsWithMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "abc")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "b")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "c")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "ab")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "ac")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "ab")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 11)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValue: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("EndsWithMatcher") {
            let sut = EndsWithMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "abc")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "b")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "c")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "ab")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: [HackleValue(value: "ac")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "ab")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 11)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValue: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("GreaterThanMatcher") {
            let sut = GreaterThanMatcher()

            it("string") {
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValue: [HackleValue(value: "42")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValue: [HackleValue(value: "42")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValue: [HackleValue(value: "42")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValue: [HackleValue(value: "20230115")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValue: [HackleValue(value: "20230115")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValue: [HackleValue(value: "20230115")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValue: [HackleValue(value: "2023-01-15")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValue: [HackleValue(value: "2023-01-15")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValue: [HackleValue(value: "2023-01-15")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "A")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValue: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValue: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "aa")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "2.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValue: [HackleValue(value: "1.0.0")]))
            }
        }
        
        describe("GreaterThanOrEqualToMatcher") {
            let sut = GreaterThanOrEqualToMatcher()

            it("string") {
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValue: [HackleValue(value: "42")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValue: [HackleValue(value: "42")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValue: [HackleValue(value: "42")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValue: [HackleValue(value: "20230115")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValue: [HackleValue(value: "20230115")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValue: [HackleValue(value: "20230115")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValue: [HackleValue(value: "2023-01-15")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValue: [HackleValue(value: "2023-01-15")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValue: [HackleValue(value: "2023-01-15")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "A")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValue: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValue: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "aa")]))
            }

            it("number") {
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "2.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValue: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("LessThanMatcher") {
            let sut = LessThanMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValue: [HackleValue(value: "42")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValue: [HackleValue(value: "42")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValue: [HackleValue(value: "42")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValue: [HackleValue(value: "20230115")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValue: [HackleValue(value: "20230115")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValue: [HackleValue(value: "20230115")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValue: [HackleValue(value: "2023-01-15")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValue: [HackleValue(value: "2023-01-15")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValue: [HackleValue(value: "2023-01-15")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "A")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValue: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValue: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "aa")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValue: [HackleValue(value: 1)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValue: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("LessThanOrEqualToMatcher") {
            let sut = LessThanOrEqualToMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValue: [HackleValue(value: "42")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValue: [HackleValue(value: "42")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValue: [HackleValue(value: "42")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValue: [HackleValue(value: "20230115")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValue: [HackleValue(value: "20230115")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValue: [HackleValue(value: "20230115")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValue: [HackleValue(value: "2023-01-15")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValue: [HackleValue(value: "2023-01-15")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValue: [HackleValue(value: "2023-01-15")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "A")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValue: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValue: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValue: [HackleValue(value: "aa")]))
            }

            it("number") {
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValue: [HackleValue(value: 1)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValue: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "1.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValue: [HackleValue(value: "1.0.0")]))
            }
        }
        
        describe("ExistMatcher") {
            let sut = ExistsMatcher()
            
            it("if null fail") {
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: nil, matchValue: []))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: nil, matchValue: []))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: nil, matchValue: []))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: nil, matchValue: []))
            }
            
            it("if not null success") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: 1, matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: true, matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "1.0.0", matchValue: []))
                
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: "abc", matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: true, matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: "1.0.0", matchValue: []))
                
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: "abc", matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: 1, matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: "1.0.0", matchValue: []))
                
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "abc", matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: 1, matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: true, matchValue: []))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValue: []))
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
