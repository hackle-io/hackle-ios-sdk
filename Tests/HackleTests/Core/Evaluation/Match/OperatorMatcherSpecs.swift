import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class OperatorMatcherSpecs: QuickSpec {
    override class func spec() {

        describe("InMatcher") {

            let sut = InMatcher()

            it("string") {
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc"), HackleValue(value: "def")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc1")]))
            }

            it("number") {
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320, matchValues: [HackleValue(value: 320)]))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValues: [HackleValue(value: 320), HackleValue(value: 321)]))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValues: [HackleValue(value: 320)]))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 320.0, matchValues: [HackleValue(value: 320.0)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 320, matchValues: [HackleValue(value: 321)]))
            }

            it("boolean") {
                assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0"), HackleValue(value: "1.0.1")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.1")]))
            }
        }

        describe("ContainsMatcher") {
            let sut = ContainsMatcher()

            it("string") {
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "a")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "b")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "c")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ab")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ac")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "ab")]))
            }

            it("number") {
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 11)]))
            }

            it("boolean") {
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("StartsWithMatcher") {
            let sut = StartsWithMatcher()

            it("string") {
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "a")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "b")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "c")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ab")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ac")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "ab")]))
            }

            it("number") {
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 11)]))
            }

            it("boolean") {
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("EndsWithMatcher") {
            let sut = EndsWithMatcher()

            it("string") {
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "abc")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "a")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "b")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "c")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ab")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: [HackleValue(value: "ac")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "ab")]))
            }

            it("number") {
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 11, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 11)]))
            }

            it("boolean") {
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("GreaterThanMatcher") {
            let sut = GreaterThanMatcher()

            it("string") {
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValues: [HackleValue(value: "42")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValues: [HackleValue(value: "42")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValues: [HackleValue(value: "42")]))

                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValues: [HackleValue(value: "20230115")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValues: [HackleValue(value: "20230115")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValues: [HackleValue(value: "20230115")]))

                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValues: [HackleValue(value: "2023-01-15")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValues: [HackleValue(value: "2023-01-15")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValues: [HackleValue(value: "2023-01-15")]))

                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "a")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "A")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValues: [HackleValue(value: "a")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValues: [HackleValue(value: "a")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "aa")]))
            }

            it("number") {
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }
        
        describe("GreaterThanOrEqualToMatcher") {
            let sut = GreaterThanOrEqualToMatcher()

            it("string") {
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValues: [HackleValue(value: "42")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValues: [HackleValue(value: "42")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValues: [HackleValue(value: "42")]))

                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValues: [HackleValue(value: "20230115")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValues: [HackleValue(value: "20230115")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValues: [HackleValue(value: "20230115")]))

                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValues: [HackleValue(value: "2023-01-15")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValues: [HackleValue(value: "2023-01-15")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValues: [HackleValue(value: "2023-01-15")]))

                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "a")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "A")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValues: [HackleValue(value: "a")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValues: [HackleValue(value: "a")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "aa")]))
            }

            it("number") {
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("LessThanMatcher") {
            let sut = LessThanMatcher()

            it("string") {
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValues: [HackleValue(value: "42")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValues: [HackleValue(value: "42")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValues: [HackleValue(value: "42")]))

                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValues: [HackleValue(value: "20230115")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValues: [HackleValue(value: "20230115")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValues: [HackleValue(value: "20230115")]))

                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValues: [HackleValue(value: "2023-01-15")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValues: [HackleValue(value: "2023-01-15")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValues: [HackleValue(value: "2023-01-15")]))

                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "a")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "A")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValues: [HackleValue(value: "a")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValues: [HackleValue(value: "a")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "aa")]))
            }

            it("number") {
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValues: [HackleValue(value: 1)]))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }

        describe("LessThanOrEqualToMatcher") {
            let sut = LessThanOrEqualToMatcher()

            it("string") {
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "41", matchValues: [HackleValue(value: "42")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "42", matchValues: [HackleValue(value: "42")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "43", matchValues: [HackleValue(value: "42")]))

                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230114", matchValues: [HackleValue(value: "20230115")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "20230115", matchValues: [HackleValue(value: "20230115")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "20230116", matchValues: [HackleValue(value: "20230115")]))

                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-14", matchValues: [HackleValue(value: "2023-01-15")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-15", matchValues: [HackleValue(value: "2023-01-15")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "2023-01-16", matchValues: [HackleValue(value: "2023-01-15")]))

                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "a")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "A")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "A", matchValues: [HackleValue(value: "a")]))
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: "aa", matchValues: [HackleValue(value: "a")]))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "a", matchValues: [HackleValue(value: "aa")]))
            }

            it("number") {
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1)]))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: 1.1, matchValues: [HackleValue(value: 1)]))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: [HackleValue(value: 1.1)]))
            }

            it("boolean") {
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: true)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: [HackleValue(value: false)]))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: false, matchValues: [HackleValue(value: true)]))
            }

            it("version") {
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "1.0.0")]))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: [HackleValue(value: "2.0.0")]))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: "2.0.0", matchValues: [HackleValue(value: "1.0.0")]))
            }
        }
        
        describe("ExistMatcher") {
            let sut = ExistsMatcher()
            
            it("if null fail") {
                assertFalse(sut.matches(valueMatcher: StringMatcher(), userValue: nil, matchValues: []))
                assertFalse(sut.matches(valueMatcher: NumberMatcher(), userValue: nil, matchValues: []))
                assertFalse(sut.matches(valueMatcher: BoolMatcher(), userValue: nil, matchValues: []))
                assertFalse(sut.matches(valueMatcher: VersionMatcher(), userValue: nil, matchValues: []))
            }
            
            it("if not null success") {
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "abc", matchValues: []))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: 1, matchValues: []))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: true, matchValues: []))
                assertTrue(sut.matches(valueMatcher: StringMatcher(), userValue: "1.0.0", matchValues: []))
                
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: "abc", matchValues: []))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: 1, matchValues: []))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: true, matchValues: []))
                assertTrue(sut.matches(valueMatcher: NumberMatcher(), userValue: "1.0.0", matchValues: []))
                
                assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: "abc", matchValues: []))
                assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: 1, matchValues: []))
                assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: true, matchValues: []))
                assertTrue(sut.matches(valueMatcher: BoolMatcher(), userValue: "1.0.0", matchValues: []))
                
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "abc", matchValues: []))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: 1, matchValues: []))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: true, matchValues: []))
                assertTrue(sut.matches(valueMatcher: VersionMatcher(), userValue: "1.0.0", matchValues: []))
            }
            
            
        }
    }

    private static func assertTrue(_ actual: Bool) {
        expect(actual).to(beTrue())
    }

    private static func assertFalse(_ actual: Bool) {
        expect(actual).to(beFalse())
    }

    private static func v(_ version: String) -> Version {
        Version.tryParse(value: version)!
    }
}
