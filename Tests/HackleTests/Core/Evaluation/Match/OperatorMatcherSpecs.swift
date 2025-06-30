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
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc"), HackleValue(value: "def")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc1")]))
            }

            it("number") {
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320, matchValues: [HackleValue(value: 320)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValues: [HackleValue(value: 320), HackleValue(value: 321)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValues: [HackleValue(value: 320)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValues: [HackleValue(value: 320.0)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 320, matchValues: [HackleValue(value: 321)]))
            }

            it("boolean") {
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0"), HackleValue(value: "1.0.1")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.1")]))
            }
        }

        describe("ContainsMatcher") {
            let sut = ContainsMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "b")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "c")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ab")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ac")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "ab")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 11)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("StartsWithMatcher") {
            let sut = StartsWithMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "b")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "c")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ab")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ac")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "ab")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 11)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("EndsWithMatcher") {
            let sut = EndsWithMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "b")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "c")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ab")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ac")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "ab")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 11)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("GreaterThanMatcher") {
            let sut = GreaterThanMatcher()

            it("string") {
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValues: [HackleValue(value: "42")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValues: [HackleValue(value: "42")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValues: [HackleValue(value: "42")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValues: [HackleValue(value: "20230115")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValues: [HackleValue(value: "20230115")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValues: [HackleValue(value: "20230115")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValues: [HackleValue(value: "2023-01-15")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValues: [HackleValue(value: "2023-01-15")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValues: [HackleValue(value: "2023-01-15")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "A")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValues: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValues: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "aa")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }
        
        describe("GreaterThanOrEqualToMatcher") {
            let sut = GreaterThanOrEqualToMatcher()

            it("string") {
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValues: [HackleValue(value: "42")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValues: [HackleValue(value: "42")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValues: [HackleValue(value: "42")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValues: [HackleValue(value: "20230115")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValues: [HackleValue(value: "20230115")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValues: [HackleValue(value: "20230115")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValues: [HackleValue(value: "2023-01-15")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValues: [HackleValue(value: "2023-01-15")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValues: [HackleValue(value: "2023-01-15")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "A")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValues: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValues: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "aa")]))
            }

            it("number") {
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("LessThanMatcher") {
            let sut = LessThanMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValues: [HackleValue(value: "42")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValues: [HackleValue(value: "42")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValues: [HackleValue(value: "42")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValues: [HackleValue(value: "20230115")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValues: [HackleValue(value: "20230115")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValues: [HackleValue(value: "20230115")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValues: [HackleValue(value: "2023-01-15")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValues: [HackleValue(value: "2023-01-15")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValues: [HackleValue(value: "2023-01-15")]))

                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "A")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValues: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValues: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "aa")]))
            }

            it("number") {
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValues: [HackleValue(value: 1)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("LessThanOrEqualToMatcher") {
            let sut = LessThanOrEqualToMatcher()

            it("string") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValues: [HackleValue(value: "42")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValues: [HackleValue(value: "42")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValues: [HackleValue(value: "42")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValues: [HackleValue(value: "20230115")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValues: [HackleValue(value: "20230115")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValues: [HackleValue(value: "20230115")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValues: [HackleValue(value: "2023-01-15")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValues: [HackleValue(value: "2023-01-15")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValues: [HackleValue(value: "2023-01-15")]))

                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "A")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValues: [HackleValue(value: "a")]))
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValues: [HackleValue(value: "a")]))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "aa")]))
            }

            it("number") {
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValues: [HackleValue(value: 1)]))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }
        
        describe("ExistMatcher") {
            let sut = ExistsMatcher()
            
            it("if null fail") {
                self.assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: nil, matchValues: []))
                self.assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: nil, matchValues: []))
                self.assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: nil, matchValues: []))
                self.assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: nil, matchValues: []))
            }
            
            it("if not null success") {
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: 1, matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: true, matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "1.0.0", matchValues: []))
                
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: "abc", matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: true, matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: "1.0.0", matchValues: []))
                
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: "abc", matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: 1, matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: "1.0.0", matchValues: []))
                
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "abc", matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: 1, matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: true, matchValues: []))
                self.assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: []))
            }
        }
        
        describe("RegexMatcher") {
            let sut: RegexMathcer = RegexMathcer()

            context("when using anchors and basic patterns") {
                it("matches the beginning of the string with ^ (Caret)") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "^ab")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "cab", matchValues: [HackleValue(value: "^ab")])).to(beFalse())
                }
                
                it("matches the end of the string with $ (Dollar)") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "a a bc", matchValues: [HackleValue(value: "bc$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "bca", matchValues: [HackleValue(value: "bc$")])).to(beFalse())
                }
            }
            
            context("when using quantifiers for full matching (using ^ and $)") {
                it("handles * (Asterisk) for 0 or more repetitions") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ac", matchValues: [HackleValue(value: "^ab*c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "^ab*c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbbc", matchValues: [HackleValue(value: "^ab*c$")])).to(beTrue())
                }
                
                it("handles + (Plus) for 1 or more repetitions") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ac", matchValues: [HackleValue(value: "^ab+c$")])).to(beFalse())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "^ab+c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbbc", matchValues: [HackleValue(value: "^ab+c$")])).to(beTrue())
                }

                it("handles ? (Question Mark) for 0 or 1 repetition") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ac", matchValues: [HackleValue(value: "^ab?c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "^ab?c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbc", matchValues: [HackleValue(value: "^ab?c$")])).to(beFalse())
                }

                it("handles {n} for exactly n repetitions") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbc", matchValues: [HackleValue(value: "^ab{2}c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "^ab{2}c$")])).to(beFalse())
                }

                it("handles {n,} for at least n repetitions") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbc", matchValues: [HackleValue(value: "^ab{2,}c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbbbc", matchValues: [HackleValue(value: "^ab{2,}c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "^ab{2,}c$")])).to(beFalse())
                }

                it("handles {n,m} for n to m repetitions") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbc", matchValues: [HackleValue(value: "^ab{2,4}c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbbbc", matchValues: [HackleValue(value: "^ab{2,4}c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "^ab{2,4}c$")])).to(beFalse())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "abbbbbc", matchValues: [HackleValue(value: "^ab{2,4}c$")])).to(beFalse())
                }
            }

            context("when using meta characters and grouping for full matching") {
                it("handles . (Dot) for any character except newline") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "a-c", matchValues: [HackleValue(value: "^a.c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "a_c", matchValues: [HackleValue(value: "^a.c$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ac", matchValues: [HackleValue(value: "^a.c$")])).to(beFalse())
                }

                it("handles | (Pipe) as an OR condition") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "cat", matchValues: [HackleValue(value: "^(cat|dog)$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "dog", matchValues: [HackleValue(value: "^(cat|dog)$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "bird", matchValues: [HackleValue(value: "^(cat|dog)$")])).to(beFalse())
                }

                it("handles () (Parentheses) for grouping") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "I love cats", matchValues: [HackleValue(value: "^I love (cats|dogs)$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "I love dogs", matchValues: [HackleValue(value: "^I love (cats|dogs)$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "I love birds", matchValues: [HackleValue(value: "^I love (cats|dogs)$")])).to(beFalse())
                }

                it("handles character sets") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "gray", matchValues: [HackleValue(value: "^gr[ae]y$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "grey", matchValues: [HackleValue(value: "^gr[ae]y$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "groy", matchValues: [HackleValue(value: "^gr[ae]y$")])).to(beFalse())
                }
                
                it("handles negated character sets") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "groy", matchValues: [HackleValue(value: "^gr[^ae]y$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "gray", matchValues: [HackleValue(value: "^gr[^ae]y$")])).to(beFalse())
                }
            }

            context("when using character classes") {
                it("handles \\d for digits") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "file-123", matchValues: [HackleValue(value: "^file-\\d+$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "file-abc", matchValues: [HackleValue(value: "^file-\\d+$")])).to(beFalse())
                }
                
                it("handles \\w for word characters") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "id_abc123", matchValues: [HackleValue(value: "^\\w+$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "id-!@#", matchValues: [HackleValue(value: "^\\w+$")])).to(beFalse())
                }
                
                it("handles \\s for whitespace characters") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "hello world", matchValues: [HackleValue(value: "^hello\\sworld$")])).to(beTrue())
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "helloworld", matchValues: [HackleValue(value: "^hello\\sworld$")])).to(beFalse())
                }
            }

            context("with a complex regex pattern") {
                let complexPattern = "^(ID|USER)-(\\d{3,5})\\s(test|prod|dev)-[a-zA-Z_]+-v\\w*!$"
                
                it("matches a perfectly valid string") {
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ID-12345 prod-user_name-v1a!", matchValues: [HackleValue(value: complexPattern)])).to(beTrue())
                }
                
                it("does not match with incorrect parts") {
                    // 시작 패턴 불일치
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "WRONG-12345 prod-user_name-v1a!", matchValues: [HackleValue(value: complexPattern)])).to(beFalse())
                    // 숫자 개수 불일치
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ID-12 prod-user_name-v1a!", matchValues: [HackleValue(value: complexPattern)])).to(beFalse())
                    // 중간 그룹 패턴 불일치
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ID-12345 qa-user_name-v1a!", matchValues: [HackleValue(value: complexPattern)])).to(beFalse())
                    // 끝 패턴 불일치
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ID-12345 prod-user-name-v1a", matchValues: [HackleValue(value: complexPattern)])).to(beFalse())
                    // 문자열 끝($) 불일치
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "ID-12345 prod-user_name-v1a! extra", matchValues: [HackleValue(value: complexPattern)])).to(beFalse())
                }
            }

            context("when handling edge cases") {
                it("returns false for an invalid regex pattern") {
                    // '['는 닫는 ']'가 없어 잘못된 패턴임
                    expect(sut.matches(valueMatcher: StringMatcher(), userValue: "any string", matchValues: [HackleValue(value: "[")])).to(beFalse())
                }
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
