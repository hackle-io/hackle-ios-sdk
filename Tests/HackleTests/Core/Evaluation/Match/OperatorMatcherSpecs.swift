import Foundation
import Quick
import Nimble
import MockingKit
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
