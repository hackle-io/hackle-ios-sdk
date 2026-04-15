import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class ScreenBuilderSpecs: QuickSpec {

    override class func spec() {

        describe("HackleScreenBuilder") {

            context("when building screen") {

                it("creates screen with name and className") {
                    // given
                    let builder = Screen.builder(name: "Home", className: "HomeViewController")

                    // when
                    let screen = builder.build()

                    // then
                    expect(screen.name).to(equal("Home"))
                    expect(screen.className).to(equal("HomeViewController"))
                    expect(screen.properties.isEmpty).to(beTrue())
                }

                it("creates screen without properties by default") {
                    // given & when
                    let screen = Screen.builder(name: "Detail", className: "DetailVC").build()

                    // then
                    expect(screen.properties.count).to(equal(0))
                }

                it("creates screen with single String property") {
                    // given & when
                    let screen = Screen.builder(name: "Home", className: "HomeVC")
                        .property("user_segment", "premium")
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(1))
                    expect(screen.properties["user_segment"] as? String).to(equal("premium"))
                }

                it("creates screen with single Int property") {
                    // given & when
                    let screen = Screen.builder(name: "Home", className: "HomeVC")
                        .property("user_id", 12345)
                        .build()

                    // then
                    expect(screen.properties["user_id"] as? Int).to(equal(12345))
                }

                it("creates screen with single Double property") {
                    // given & when
                    let screen = Screen.builder(name: "Home", className: "HomeVC")
                        .property("price", 99.99)
                        .build()

                    // then
                    expect(screen.properties["price"] as? Double).to(equal(99.99))
                }

                it("creates screen with single Bool property") {
                    // given & when
                    let screen = Screen.builder(name: "Home", className: "HomeVC")
                        .property("is_premium", true)
                        .build()

                    // then
                    expect(screen.properties["is_premium"] as? Bool).to(equal(true))
                }

                it("creates screen with Array property") {
                    // given & when
                    let screen = Screen.builder(name: "Home", className: "HomeVC")
                        .property("tags", ["tag1", "tag2", "tag3"])
                        .build()

                    // then
                    let tags = screen.properties["tags"] as? [String]
                    expect(tags).to(equal(["tag1", "tag2", "tag3"]))
                }

                it("creates screen with multiple properties") {
                    // given & when
                    let screen = Screen.builder(name: "Product", className: "ProductVC")
                        .property("product_id", "ABC-123")
                        .property("category", "electronics")
                        .property("price", 299.99)
                        .property("in_stock", true)
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(4))
                    expect(screen.properties["product_id"] as? String).to(equal("ABC-123"))
                    expect(screen.properties["category"] as? String).to(equal("electronics"))
                    expect(screen.properties["price"] as? Double).to(equal(299.99))
                    expect(screen.properties["in_stock"] as? Bool).to(equal(true))
                }
            }

            context("properties() method") {

                it("adds multiple properties at once") {
                    // given
                    let props: [String: Any] = [
                        "key1": "value1",
                        "key2": 42,
                        "key3": true
                    ]

                    // when
                    let screen = Screen.builder(name: "Test", className: "TestVC")
                        .properties(props)
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(3))
                    expect(screen.properties["key1"] as? String).to(equal("value1"))
                    expect(screen.properties["key2"] as? Int).to(equal(42))
                    expect(screen.properties["key3"] as? Bool).to(equal(true))
                }

                it("merges with existing properties") {
                    // given & when
                    let screen = Screen.builder(name: "Test", className: "TestVC")
                        .property("existing_key", "existing_value")
                        .properties(["new_key": "new_value"])
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(2))
                    expect(screen.properties["existing_key"] as? String).to(equal("existing_value"))
                    expect(screen.properties["new_key"] as? String).to(equal("new_value"))
                }

                it("overrides property when duplicate key is provided") {
                    // given & when
                    let screen = Screen.builder(name: "Test", className: "TestVC")
                        .property("key", "first_value")
                        .property("key", "second_value")
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(1))
                    expect(screen.properties["key"] as? String).to(equal("second_value"))
                }
            }

            context("property validation") {

                it("enforces maximum 128 properties") {
                    // given
                    let builder = Screen.builder(name: "Test", className: "TestVC")

                    // Add 129 properties
                    for i in 1...129 {
                        builder.property("key\(i)", i)
                    }

                    // when
                    let screen = builder.build()

                    // then
                    expect(screen.properties.count).to(equal(128))
                }

                it("validates key length (max 128 characters)") {
                    // given
                    let validKey = String(repeating: "a", count: 128)
                    let invalidKey = String(repeating: "b", count: 129)

                    // when
                    let screen = Screen.builder(name: "Test", className: "TestVC")
                        .property(validKey, "valid")
                        .property(invalidKey, "invalid")
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(1))
                    expect(screen.properties[validKey] as? String).to(equal("valid"))
                }

                it("validates value length (max 1024 characters for strings)") {
                    // given
                    let validValue = String(repeating: "a", count: 1024)
                    let invalidValue = String(repeating: "b", count: 1025)

                    // when
                    let screen = Screen.builder(name: "Test", className: "TestVC")
                        .property("valid_key", validValue)
                        .property("invalid_key", invalidValue)
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(1))
                    expect(screen.properties["valid_key"] as? String).to(equal(validValue))
                }

                it("filters unsupported types (objects)") {
                    // given
                    let user = User.builder().build()

                    // when
                    let screen = Screen.builder(name: "Test", className: "TestVC")
                        .property("user", user)
                        .property("valid_key", "valid_value")
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(1))
                    expect(screen.properties["valid_key"] as? String).to(equal("valid_value"))
                }

                it("filters nil values") {
                    // given & when
                    let screen = Screen.builder(name: "Test", className: "TestVC")
                        .property("nil_key", nil)
                        .property("valid_key", "valid_value")
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(1))
                    expect(screen.properties["valid_key"] as? String).to(equal("valid_value"))
                }

                it("filters invalid array elements") {
                    // given & when
                    let screen = Screen.builder(name: "Test", className: "TestVC")
                        .property("array_with_nil", [1, 2, nil, 3])
                        .property("array_with_long_string", [String(repeating: "a", count: 1025)])
                        .build()

                    // then
                    expect((screen.properties["array_with_nil"] as? [Int])).to(equal([1, 2, 3]))
                    expect((screen.properties["array_with_long_string"] as? [String])?.isEmpty).to(beTrue())
                }
            }

            context("method chaining") {

                it("allows fluent API") {
                    // given & when
                    let screen = Screen.builder(name: "Home", className: "HomeVC")
                        .property("key1", "value1")
                        .property("key2", 42)
                        .properties(["key3": true])
                        .property("key4", 3.14)
                        .build()

                    // then
                    expect(screen.properties.count).to(equal(4))
                }

                it("returns self for property() method") {
                    // given
                    let builder = Screen.builder(name: "Test", className: "TestVC")

                    // when
                    let returnedBuilder = builder.property("key", "value")

                    // then - same instance
                    expect(builder === returnedBuilder).to(beTrue())
                }

                it("returns self for properties() method") {
                    // given
                    let builder = Screen.builder(name: "Test", className: "TestVC")

                    // when
                    let returnedBuilder = builder.properties(["key": "value"])

                    // then - same instance
                    expect(builder === returnedBuilder).to(beTrue())
                }
            }

            context("backward compatibility") {

                it("deprecated init still works") {
                    // given & when
                    let screen = Screen(name: "Legacy", className: "LegacyVC")

                    // then
                    expect(screen.name).to(equal("Legacy"))
                    expect(screen.className).to(equal("LegacyVC"))
                    expect(screen.properties.isEmpty).to(beTrue())
                }

                it("deprecated init produces same result as builder") {
                    // given & when
                    let screenFromDeprecatedInit = Screen(name: "Test", className: "TestVC")
                    let screenFromBuilder = Screen.builder(name: "Test", className: "TestVC").build()

                    // then
                    expect(screenFromDeprecatedInit).to(equal(screenFromBuilder))
                    expect(screenFromDeprecatedInit.name).to(equal(screenFromBuilder.name))
                    expect(screenFromDeprecatedInit.className).to(equal(screenFromBuilder.className))
                    expect(screenFromDeprecatedInit.properties.isEmpty).to(beTrue())
                    expect(screenFromBuilder.properties.isEmpty).to(beTrue())
                }

                it("deprecated init creates screen equivalent to builder without properties") {
                    // given
                    let name = "HomeScreen"
                    let className = "HomeViewController"

                    // when
                    let legacyScreen = Screen(name: name, className: className)
                    let modernScreen = Screen.builder(name: name, className: className).build()

                    // then - screens should be equal
                    expect(legacyScreen.isEqual(modernScreen)).to(beTrue())
                    expect(modernScreen.isEqual(legacyScreen)).to(beTrue())

                    // then - both should have empty properties
                    expect(NSDictionary(dictionary: legacyScreen.properties).isEqual(to: modernScreen.properties)).to(beTrue())
                }
            }

            context("screen equality") {

                it("screens with same name and className but different properties are equal") {
                    // given
                    let screen1 = Screen.builder(name: "Home", className: "HomeVC")
                        .property("user_id", 123)
                        .property("session", "abc")
                        .build()

                    let screen2 = Screen.builder(name: "Home", className: "HomeVC")
                        .property("user_id", 456)
                        .property("session", "xyz")
                        .build()

                    // when & then
                    expect(screen1.isEqual(screen2)).to(beTrue())
                    expect(screen2.isEqual(screen1)).to(beTrue())
                    expect(screen1).to(equal(screen2))
                }

                it("screens with same name and className, one with properties and one without, are equal") {
                    // given
                    let screenWithProperties = Screen.builder(name: "Detail", className: "DetailVC")
                        .property("product_id", "ABC-123")
                        .property("category", "electronics")
                        .build()

                    let screenWithoutProperties = Screen.builder(name: "Detail", className: "DetailVC")
                        .build()

                    // when & then
                    expect(screenWithProperties.isEqual(screenWithoutProperties)).to(beTrue())
                    expect(screenWithoutProperties.isEqual(screenWithProperties)).to(beTrue())
                }

                it("screens with different name but same properties are not equal") {
                    // given
                    let screen1 = Screen.builder(name: "Home", className: "HomeVC")
                        .property("key", "value")
                        .build()

                    let screen2 = Screen.builder(name: "Detail", className: "HomeVC")
                        .property("key", "value")
                        .build()

                    // when & then
                    expect(screen1.isEqual(screen2)).to(beFalse())
                    expect(screen2.isEqual(screen1)).to(beFalse())
                }

                it("screens with different className but same properties are not equal") {
                    // given
                    let screen1 = Screen.builder(name: "Home", className: "HomeVC")
                        .property("key", "value")
                        .build()

                    let screen2 = Screen.builder(name: "Home", className: "DetailVC")
                        .property("key", "value")
                        .build()

                    // when & then
                    expect(screen1.isEqual(screen2)).to(beFalse())
                    expect(screen2.isEqual(screen1)).to(beFalse())
                }

                it("screen equality is consistent with deprecated init") {
                    // given
                    let legacyScreen = Screen(name: "Settings", className: "SettingsVC")
                    let modernScreenWithProperties = Screen.builder(name: "Settings", className: "SettingsVC")
                        .property("theme", "dark")
                        .property("notifications", true)
                        .build()

                    // when & then - should be equal despite different properties
                    expect(legacyScreen.isEqual(modernScreenWithProperties)).to(beTrue())
                    expect(modernScreenWithProperties.isEqual(legacyScreen)).to(beTrue())
                }
            }

        }
    }
}
