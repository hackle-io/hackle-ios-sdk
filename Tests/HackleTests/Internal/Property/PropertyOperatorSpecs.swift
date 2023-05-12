import Foundation
import Quick
import Nimble
@testable import Hackle

class PropertyOperatorSpecs: QuickSpec {
    override func spec() {
        it("PropertySetOperator") {
            let sut = PropertySetOperator()

            let p1 = PropertiesBuilder()
                .add("name", "Yong")
                .add("location", "Seoul")
                .add("job", "Server Developer")
                .build()

            let p2 = PropertiesBuilder()
                .add("job", "SDK Developer")
                .add("company", "Hackle")
                .build()

            sut.verify([:], p1, p1)
            sut.verify(p1, [:], p1)
            sut.verify(p1, p2, PropertiesBuilder()
                .add("name", "Yong")
                .add("location", "Seoul")
                .add("job", "SDK Developer")
                .add("company", "Hackle")
                .build()
            )
        }

        it("PropertySetOnceOperator") {
            let sut = PropertySetOnceOperator()

            let p1 = PropertiesBuilder()
                .add("name", "Yong")
                .add("location", "Seoul")
                .add("job", "Server Developer")
                .build()

            let p2 = PropertiesBuilder()
                .add("job", "SDK Developer")
                .add("company", "Hackle")
                .build()

            sut.verify([:], p1, p1)
            sut.verify(p1, [:], p1)
            sut.verify(p1, p2, PropertiesBuilder()
                .add("name", "Yong")
                .add("location", "Seoul")
                .add("job", "Server Developer")
                .add("company", "Hackle")
                .build()
            )
        }

        it("PropertyUnsetOperator") {
            let sut = PropertyUnsetOperator()

            let p1 = PropertiesBuilder()
                .add("name", "Yong")
                .add("location", "Seoul")
                .add("job", "Server Developer")
                .build()

            let p2 = PropertiesBuilder()
                .add("job", "SDK Developer")
                .add("company", "Hackle")
                .build()

            sut.verify([:], p1, p1)
            sut.verify(p1, [:], p1)
            sut.verify(p1, p2, PropertiesBuilder()
                .add("name", "Yong")
                .add("location", "Seoul")
                .build()
            )
        }


        it("PropertyIncrementOperator") {
            let sut = PropertyIncrementOperator()

            func verify(_ base: Any?, _ value: Any?, _ expected: Any?) {
                sut.verify(
                    PropertiesBuilder().add("number", base).build(),
                    PropertiesBuilder().add("number", value).build(),
                    PropertiesBuilder().add("number", expected).build()
                )
            }

            verify(nil, nil, nil)
            verify(nil, 42, 42)
            verify(nil, "42", nil)

            verify(42, nil, 42)
            verify(42, 42, 84.0)
            verify(42, "42", 42)

            verify("42", nil, "42")
            verify("42", 42, "42")
            verify("42", "42", "42")
        }

        it("PropertyAppendOperator") {
            let sut = PropertyAppendOperator()

            sut.verify(nil, nil, nil)
            sut.verify(nil, 1, [1])
            sut.verify(nil, [1], [1])
            sut.verify(nil, [1, 2, 3], [1, 2, 3])
            sut.verify(nil, [1, 2, 3, 1, 2], [1, 2, 3, 1, 2])

            sut.verify(1, nil, 1)
            sut.verify(1, 1, [1, 1])
            sut.verify(1, [1], [1, 1])
            sut.verify(1, [1, 2, 3], [1, 1, 2, 3])
            sut.verify(1, [1, 2, 3, 1, 2], [1, 1, 2, 3, 1, 2])

            sut.verify(2, nil, 2)
            sut.verify(2, 1, [2, 1])
            sut.verify(2, [1], [2, 1])
            sut.verify(2, [1, 2, 3], [2, 1, 2, 3])
            sut.verify(2, [1, 2, 3, 1, 2], [2, 1, 2, 3, 1, 2])

            sut.verify([1], nil, [1])
            sut.verify([1], 1, [1, 1])
            sut.verify([1], [1], [1, 1])
            sut.verify([1], [1, 2, 3], [1, 1, 2, 3])
            sut.verify([1], [1, 2, 3, 1, 2], [1, 1, 2, 3, 1, 2])

            sut.verify([1, 3, 5], nil, [1, 3, 5])
            sut.verify([1, 3, 5], 1, [1, 3, 5, 1])
            sut.verify([1, 3, 5], [1], [1, 3, 5, 1])
            sut.verify([1, 3, 5], [1, 2, 3], [1, 3, 5, 1, 2, 3])
            sut.verify([1, 3, 5], [1, 2, 3, 1, 2], [1, 3, 5, 1, 2, 3, 1, 2])
        }

        it("PropertyAppendOnceOperator") {
            let sut = PropertyAppendOnceOperator()

            sut.verify(nil, 1, [1])
            sut.verify(nil, [1], [1])
            sut.verify(nil, [1, 2, 3], [1, 2, 3])
            sut.verify(nil, [1, 2, 3, 1, 2], [1, 2, 3])

            sut.verify(1, 1, [1])
            sut.verify(1, [1], [1])
            sut.verify(1, [1, 2, 3], [1, 2, 3])
            sut.verify(1, [1, 2, 3, 1, 2], [1, 2, 3])

            sut.verify(2, 1, [2, 1])
            sut.verify(2, [1], [2, 1])
            sut.verify(2, [1, 2, 3], [2, 1, 3])
            sut.verify(2, [1, 2, 3, 1, 2], [2, 1, 3])

            sut.verify([1], 1, [1])
            sut.verify([1], [1], [1])
            sut.verify([1], [1, 2, 3], [1, 2, 3])
            sut.verify([1], [1, 2, 3, 1, 2], [1, 2, 3])

            sut.verify([1, 3, 5], 1, [1, 3, 5])
            sut.verify([1, 3, 5], [1], [1, 3, 5])
            sut.verify([1, 3, 5], [1, 2, 3], [1, 3, 5, 2])
            sut.verify([1, 3, 5], [1, 2, 3, 1, 2], [1, 3, 5, 2])
        }

        it("PropertyPrependOperator") {
            let sut = PropertyPrependOperator()

            sut.verify(nil, 1, [1])
            sut.verify(nil, [1], [1])
            sut.verify(nil, [1, 2, 3], [1, 2, 3])
            sut.verify(nil, [1, 2, 3, 1, 2], [1, 2, 3, 1, 2])

            sut.verify(1, 1, [1, 1])
            sut.verify(1, [1], [1, 1])
            sut.verify(1, [1, 2, 3], [1, 2, 3, 1])
            sut.verify(1, [1, 2, 3, 1, 2], [1, 2, 3, 1, 2, 1])

            sut.verify(2, 1, [1, 2])
            sut.verify(2, [1], [1, 2])
            sut.verify(2, [1, 2, 3], [1, 2, 3, 2])
            sut.verify(2, [1, 2, 3, 1, 2], [1, 2, 3, 1, 2, 2])

            sut.verify([1], 1, [1, 1])
            sut.verify([1], [1], [1, 1])
            sut.verify([1], [1, 2, 3], [1, 2, 3, 1])
            sut.verify([1], [1, 2, 3, 1, 2], [1, 2, 3, 1, 2, 1])

            sut.verify([1, 3, 5], 1, [1, 1, 3, 5])
            sut.verify([1, 3, 5], [1], [1, 1, 3, 5])
            sut.verify([1, 3, 5], [1, 2, 3], [1, 2, 3, 1, 3, 5])
            sut.verify([1, 3, 5], [1, 2, 3, 1, 2], [1, 2, 3, 1, 2, 1, 3, 5])
        }

        it("PropertyPrependOnceOperator") {
            let sut = PropertyPrependOnceOperator()

            sut.verify(nil, 1, [1])
            sut.verify(nil, [1], [1])
            sut.verify(nil, [1, 2, 3], [1, 2, 3])
            sut.verify(nil, [1, 2, 3, 1, 2], [1, 2, 3])

            sut.verify(1, 1, [1])
            sut.verify(1, [1], [1])
            sut.verify(1, [1, 2, 3], [2, 3, 1])
            sut.verify(1, [1, 2, 3, 1, 2], [2, 3, 1])

            sut.verify(2, 1, [1, 2])
            sut.verify(2, [1], [1, 2])
            sut.verify(2, [1, 2, 3], [1, 3, 2])
            sut.verify(2, [1, 2, 3, 1, 2], [1, 3, 2])

            sut.verify([1], 1, [1])
            sut.verify([1], [1], [1])
            sut.verify([1], [1, 2, 3], [2, 3, 1])
            sut.verify([1], [1, 2, 3, 1, 2], [2, 3, 1])

            sut.verify([1, 3, 5], 1, [1, 3, 5])
            sut.verify([1, 3, 5], [1], [1, 3, 5])
            sut.verify([1, 3, 5], [1, 2, 3], [2, 1, 3, 5])
            sut.verify([1, 3, 5], [1, 2, 3, 1, 2], [2, 1, 3, 5])
        }

        it("PropertyRemoveOperator") {
            let sut = PropertyRemoveOperator()

            sut.verify(nil, 1, [])
            sut.verify(nil, [1], [])
            sut.verify(nil, [1, 2, 3], [])
            sut.verify(nil, [1, 2, 3, 1, 2], [])

            sut.verify(1, 1, [])
            sut.verify(1, [1], [])
            sut.verify(1, [1, 2, 3], [])
            sut.verify(1, [1, 2, 3, 1, 2], [])

            sut.verify(2, 1, [2])
            sut.verify(2, [1], [2])
            sut.verify(2, [1, 2, 3], [])
            sut.verify(2, [1, 2, 3, 1, 2], [])

            sut.verify([1], 1, [])
            sut.verify([1], [1], [])
            sut.verify([1], [1, 2, 3], [])
            sut.verify([1], [1, 2, 3, 1, 2], [])

            sut.verify([1, 3, 5], 1, [3, 5])
            sut.verify([1, 3, 5], [1], [3, 5])
            sut.verify([1, 3, 5], [1, 2, 3], [5])
            sut.verify([1, 3, 5], [1, 2, 3, 1, 2], [5])

            sut.verify([1, 2, 3, 2, 1], [1], [2, 3, 2])
        }

        it("PropertyClearAllOperator") {
            PropertyClearAllOperator().verify(PropertiesBuilder().add("a", "a").build(), [:], [:])
        }
    }
}

fileprivate extension ArrayPropertyOperator {
    func verify(_ base: Any?, _ value: Any?, _ expected: Any?) {
        verify(
            PropertiesBuilder().add("arr", base).build(),
            PropertiesBuilder().add("arr", value).build(),
            PropertiesBuilder().add("arr", expected).build()
        )
    }
}

fileprivate extension PropertyOperator {
    func verify(_ base: [String: Any], _ properties: [String: Any], _ expected: [String: Any]) {
        let actual = operate(base: base, properties: properties)
        expect(actual.count) == expected.count
        for (key, value) in actual {
            expect(PropertyOperators.equals(value, expected[key] as Any)) == true
        }
    }
}
