import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class HackleBridgeSpec : QuickSpec {
    
    override func spec() {
        it("is invocable string") {
            expect(HackleBridge.isInvocableString(string: "{\"_hackle\":{\"_command\":\"\"}}")) == true
            expect(HackleBridge.isInvocableString(string: "{\"_hackle\":\"\"}}")) == false
            expect(HackleBridge.isInvocableString(string: "{\"_hackle\":{}}}")) == false
            expect(HackleBridge.isInvocableString(string: "{\"something\":{\"_command\":\"\"}}")) == false
            expect(HackleBridge.isInvocableString(string: "{")) == false
            expect(HackleBridge.isInvocableString(string: "")) == false
        }
        describe("invoke") {
            it("get app sdk key") {
                let sdkKey = "abcdef1234"
                let mock = MockHackleApp(sdkKey: sdkKey)
                let result = HackleBridge.invoke(app: mock, string: """
                {
                    "_hackle": {
                        "_command": "getAppSDKKey"
                    }
                }
                """)
                expect(result) == sdkKey
            }
            it("is initialized") {
                let mock = MockHackleApp()
                let result = HackleBridge.invoke(app: mock, string: """
                {
                    "_hackle": {
                        "_command": "isInitialized"
                    }
                }
                """)
                expect(result) == true.description
            }
            it("get session id") {
                let sessionId = "1234567890.abcdefgh"
                let mock = MockHackleApp(sessonId: sessionId)
                let result = HackleBridge.invoke(app: mock, string: """
                {
                    "_hackle": {
                        "_command": "getSessionId"
                    }
                }
                """)
                expect(result) == sessionId
            }
            it("get user") {
                let user = HackleUserBuilder()
                    .id("myid")
                    .userId("1234")
                    .identifier("foo", "bar")
                    .property("bar", "foo")
                    .build()
                let mock = MockHackleApp(user: user)
                let result = HackleBridge.invoke(app: mock, string: """
                {
                    "_hackle": {
                        "_command": "getUser"
                    }
                }
                """)
                let dict = result!.jsonObject()!
                expect(dict["id"] as? String) == user.id
                expect(dict["userId"] as? String) == user.userId
                let identifiers = dict["identifiers"] as! [String: String]
                expect(identifiers.count) == 1
                expect(identifiers).to(equal(user.identifiers))
                let properties = dict["properties"] as! [String: Any]
                expect(properties.count) == 1
                expect(properties["bar"] as? String) == user.properties["bar"] as? String
            }
            describe("set user") {
                it("normal case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "setUser",
                            "_parameters": {
                                "user": {
                                    "id": "foo",
                                    "userId": "bar",
                                    "identifiers": {
                                        "foobar": "foofoo",
                                        "foobar2": "barbar"
                                    },
                                    "properties": {
                                        "null": null,
                                        "number": 123,
                                        "string": "text",
                                        "array": [123, "123", null],
                                        "map": { "key": "value" }
                                    }
                                }
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.setUserRef.invokations().count) == 1
                    let arguments = mock.setUserRef.firstInvokation().arguments
                    expect(arguments.id) == "foo"
                    expect(arguments.userId) == "bar"
                    expect(arguments.identifiers).to(equal(["foobar": "foofoo", "foobar2": "barbar"]))
                    expect(arguments.properties["number"] as? Double) == 123.0
                    expect(arguments.properties["string"] as? String) == "text"
                    let array = arguments.properties["array"] as! Array<Any>
                    expect(array.count) == 2
                    expect(array[0] as? Double) == 123.0
                    expect(array[1] as? String) == "123"
                    expect(arguments.properties["map"]).to(beNil())
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "setUser",
                            "_parameters": {}
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.setUserRef.invokations().count) == 0
                    expect(mock.setUserIdRef.invokations().count) == 0
                }
            }
            describe("set user id") {
                it("normal case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "setUserId",
                            "_parameters": {
                                "userId": "abcd123"
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.setUserIdRef.invokations().count) == 1
                    expect(mock.setUserIdRef.firstInvokation().arguments) == "abcd123"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "setUserId",
                            "_parameters": {}
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.setUserIdRef.invokations().count) == 0
                }
            }
            describe("set device id") {
                it("normal case") {
                    let mock = MockHackleApp(deviceId: "before")
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "setDeviceId",
                            "_parameters": {
                                "deviceId": "after"
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.deviceId) == "after"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp(deviceId: "before")
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "setDeviceId",
                            "_parameters": {}
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.deviceId) == "before"
                }
            }
            describe("set user property") {
                it("normal case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "setUserProperty",
                            "_parameters": {
                                "key": "foo",
                                "value": "bar"
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.setUserPropertyRef.invokations().count) == 1
                    expect(mock.setUserPropertyRef.firstInvokation().arguments.0) == "foo"
                    expect(mock.setUserPropertyRef.firstInvokation().arguments.1 as? String) == "bar"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "setUserProperty",
                            "_parameters": {
                                "value": "bar"
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.setUserPropertyRef.invokations().count) == 0
                }
            }
            describe("update user properties") {
                it("normal case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "updateUserProperties",
                            "_parameters": {
                                "operations": {
                                    "$set": {
                                        "null": null,
                                        "number": 123,
                                        "string": "text",
                                        "array": [123, "123", null],
                                        "map": { "key": "value" }
                                    },
                                    "$setOnce": {
                                        "foo": "bar"
                                    }
                                }
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.updateUserPropertiesRef.invokations().count) == 1
                    let arguments = mock.updateUserPropertiesRef.firstInvokation().arguments
                    let dict = arguments.asDictionary()
                    let set = dict[PropertyOperation.set]!
                    expect(set.count) == 3
                    expect(set["number"] as? Double) == 123.0
                    expect(set["string"] as? String) == "text"
                    let array = set["array"] as! Array<Any>
                    expect(array.count) == 2
                    expect(array[0] as? Double) == 123.0
                    expect(array[1] as? String) == "123"
                    let setOnce = dict[PropertyOperation.setOnce]!
                    expect(setOnce["foo"] as? String) == "bar"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "updateUserProperties",
                            "_parameters": {}
                        }
                    }
                    """)
                    expect(mock.updateUserPropertiesRef.invokations().count) == 0
                }
            }
            it("reset user") {
                let mock = MockHackleApp()
                let result = HackleBridge.invoke(app: mock, string: "{\"_hackle\":{\"_command\":\"resetUser\"}}")
                expect(result).to(beNil())
                expect(mock.resetUserRef.invokations().count) == 1
            }
            describe("variation") {
                context("normal") {
                    it("happy case") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variation",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "defaultVariation": "D"
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationRef.invokations().count) == 1
                        let arguments = mock.variationRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "D"
                    }
                    it("expect 'A' default variation parameter") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variation",
                                "_parameters": {
                                    "experimentKey": 123
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationRef.invokations().count) == 1
                        let arguments = mock.variationRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "A"
                    }
                }
                context("with user id") {
                    it("happy case") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variation",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "defaultVariation": "D",
                                    "userId": "abcd1234"
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationWithUserIdRef.invokations().count) == 1
                        let arguments = mock.variationWithUserIdRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "abcd1234"
                        expect(arguments.2) == "D"
                    }
                    it("expect 'A' default variation parameter") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variation",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "userId": "abcd1234"
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationWithUserIdRef.invokations().count) == 1
                        let arguments = mock.variationWithUserIdRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "abcd1234"
                        expect(arguments.2) == "A"
                    }
                }
                context("with user") {
                    it("normal case") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variation",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "defaultVariation": "D",
                                    "user": {
                                        "id": "foo"
                                    }
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationWithUserRef.invokations().count) == 1
                        let arguments = mock.variationWithUserRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1.id) == "foo"
                        expect(arguments.2) == "D"
                    }
                    it("expect 'A' default variation parameter") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variation",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "user": {
                                        "id": "foo"
                                    }
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationWithUserRef.invokations().count) == 1
                        let arguments = mock.variationWithUserRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1.id) == "foo"
                        expect(arguments.2) == "A"
                    }
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "variation",
                            "_parameters": {
                                "defaultVariation": "D"
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.variationRef.invokations().count) == 0
                    expect(mock.variationWithUserIdRef.invokations().count) == 0
                    expect(mock.variationWithUserRef.invokations().count) == 0
                }
            }
            describe("variation detail") {
                context("normal") {
                    it("happy case") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variationDetail",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "defaultVariation": "D"
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationDetailRef.invokations().count) == 1
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "D"
                    }
                    it("expect 'A' default variation parameter") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variationDetail",
                                "_parameters": {
                                    "experimentKey": 123
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationDetailRef.invokations().count) == 1
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "A"
                    }
                }
                context("with user id") {
                    it("happy case") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variationDetail",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "defaultVariation": "D",
                                    "userId": "abcd1234"
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationDetailWithUserIdRef.invokations().count) == 1
                        let arguments = mock.variationDetailWithUserIdRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "abcd1234"
                        expect(arguments.2) == "D"
                    }
                    it("expect 'A' default variation parameter") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variationDetail",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "userId": "abcd1234"
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationDetailWithUserIdRef.invokations().count) == 1
                        let arguments = mock.variationDetailWithUserIdRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "abcd1234"
                        expect(arguments.2) == "A"
                    }
                }
                context("with user") {
                    it("normal case") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variationDetail",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "defaultVariation": "D",
                                    "user": {
                                        "id": "foo"
                                    }
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationDetailWithUserRef.invokations().count) == 1
                        let arguments = mock.variationDetailWithUserRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1.id) == "foo"
                        expect(arguments.2) == "D"
                    }
                    it("expect 'A' default variation parameter") {
                        let mock = MockHackleApp()
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "variationDetail",
                                "_parameters": {
                                    "experimentKey": 123,
                                    "user": {
                                        "id": "foo"
                                    }
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(mock.variationDetailWithUserRef.invokations().count) == 1
                        let arguments = mock.variationDetailWithUserRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1.id) == "foo"
                        expect(arguments.2) == "A"
                    }
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "variationDetail",
                            "_parameters": {
                                "defaultVariation": "D"
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.variationDetailRef.invokations().count) == 0
                    expect(mock.variationDetailWithUserIdRef.invokations().count) == 0
                    expect(mock.variationDetailWithUserRef.invokations().count) == 0
                }
            }
            describe("is feature on") {
                it("normal case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "isFeatureOn",
                            "_parameters": {
                                "featureKey": 123
                            }
                        }
                    }
                    """)
                    expect(result).notTo(beNil())
                    expect(mock.isFeatureOnRef.invokations().count) == 1
                    let arguments = mock.isFeatureOnRef.firstInvokation().arguments
                    expect(arguments) == 123
                }
                it("with user id case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "isFeatureOn",
                            "_parameters": {
                                "featureKey": 123,
                                "userId": "abcd1234"
                            }
                        }
                    }
                    """)
                    expect(result).notTo(beNil())
                    expect(mock.isFeatureOnWithUserIdRef.invokations().count) == 1
                    let arguments = mock.isFeatureOnWithUserIdRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                    expect(arguments.1) == "abcd1234"
                }
                it("with user case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "isFeatureOn",
                            "_parameters": {
                                "featureKey": 123,
                                "user": {
                                    "id": "foo"
                                }
                            }
                        }
                    }
                    """)
                    expect(result).notTo(beNil())
                    expect(mock.isFeatureOnWithUserRef.invokations().count) == 1
                    let arguments = mock.isFeatureOnWithUserRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                    expect(arguments.1.id) == "foo"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "isFeatureOn",
                            "_parameters": {}
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.isFeatureOnRef.invokations().count) == 0
                    expect(mock.isFeatureOnWithUserIdRef.invokations().count) == 0
                    expect(mock.isFeatureOnWithUserRef.invokations().count) == 0
                }
            }
            
            describe("feature flag detail") {
                it("normal case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "featureFlagDetail",
                            "_parameters": {
                                "featureKey": 123
                            }
                        }
                    }
                    """)
                    expect(result).notTo(beNil())
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments) == 123
                }
                it("with user id") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "featureFlagDetail",
                            "_parameters": {
                                "featureKey": 123,
                                "userId": "abcd1234"
                            }
                        }
                    }
                    """)
                    expect(result).notTo(beNil())
                    expect(mock.featureFlagDetailWithUserIdRef.invokations().count) == 1
                    let arguments = mock.featureFlagDetailWithUserIdRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                    expect(arguments.1) == "abcd1234"
                }
                it("with user") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "featureFlagDetail",
                            "_parameters": {
                                "featureKey": 123,
                                "user": {
                                    "id": "foo"
                                }
                            }
                        }
                    }
                    """)
                    expect(result).notTo(beNil())
                    expect(mock.featureFlagDetailWithUserRef.invokations().count) == 1
                    let arguments = mock.featureFlagDetailWithUserRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                    expect(arguments.1.id) == "foo"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "featureFlagDetail",
                            "_parameters": {}
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.featureFlagDetailRef.invokations().count) == 0
                    expect(mock.featureFlagDetailWithUserIdRef.invokations().count) == 0
                    expect(mock.featureFlagDetailWithUserRef.invokations().count) == 0
                }
            }
            
            describe("track") {
                it("normal case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "track",
                            "_parameters": {
                                "event": {
                                    "key": "abcd1234",
                                    "value": 1234,
                                    "properties": {
                                        "null": null,
                                        "number": 123,
                                        "string": "text",
                                        "array": [123, "123", null],
                                        "map": { "key": "value" }
                                    }
                                }
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.trackWithEventRef.invokations().count) == 1
                    let arguments = mock.trackWithEventRef.firstInvokation().arguments
                    expect(arguments.key) == "abcd1234"
                    expect(arguments.value) == 1234
                    expect(arguments.properties!.count) == 3
                    expect(arguments.properties!["number"] as? Double) == 123.0
                    expect(arguments.properties!["string"] as? String) == "text"
                    let array = arguments.properties!["array"] as! Array<Any>
                    expect(array.count) == 2
                    expect(array[0] as? Double) == 123.0
                    expect(array[1] as? String) == "123"
                    expect(arguments.properties!["map"]).to(beNil())
                }
                it("with user id case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "track",
                            "_parameters": {
                                "event": {
                                    "key": "abcd1234",
                                    "value": 1234,
                                    "properties": {
                                        "null": null,
                                        "number": 123,
                                        "string": "text",
                                        "array": [123, "123", null],
                                        "map": { "key": "value" }
                                    }
                                },
                                "userId": "foo"
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.trackWithEventUserIdRef.invokations().count) == 1
                    let arguments = mock.trackWithEventUserIdRef.firstInvokation().arguments
                    expect(arguments.0.key) == "abcd1234"
                    expect(arguments.0.value) == 1234
                    expect(arguments.0.properties!.count) == 3
                    expect(arguments.0.properties!["number"] as? Double) == 123.0
                    expect(arguments.0.properties!["string"] as? String) == "text"
                    let array = arguments.0.properties!["array"] as! Array<Any>
                    expect(array.count) == 2
                    expect(array[0] as? Double) == 123.0
                    expect(array[1] as? String) == "123"
                    expect(arguments.0.properties!["map"]).to(beNil())
                    expect(arguments.1) == "foo"
                }
                it("with user case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "track",
                            "_parameters": {
                                "event": {
                                    "key": "abcd1234",
                                    "value": 1234,
                                    "properties": {
                                        "null": null,
                                        "number": 123,
                                        "string": "text",
                                        "array": [123, "123", null],
                                        "map": { "key": "value" }
                                    }
                                },
                                "user": {
                                    "id": "foo"
                                }
                            }
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.trackWithEventUserRef.invokations().count) == 1
                    let arguments = mock.trackWithEventUserRef.firstInvokation().arguments
                    expect(arguments.0.key) == "abcd1234"
                    expect(arguments.0.value) == 1234
                    expect(arguments.0.properties!.count) == 3
                    expect(arguments.0.properties!["number"] as? Double) == 123.0
                    expect(arguments.0.properties!["string"] as? String) == "text"
                    let array = arguments.0.properties!["array"] as! Array<Any>
                    expect(array.count) == 2
                    expect(array[0] as? Double) == 123.0
                    expect(array[1] as? String) == "123"
                    expect(arguments.0.properties!["map"]).to(beNil())
                    expect(arguments.1.id) == "foo"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let result = HackleBridge.invoke(app: mock, string: """
                    {
                        "_hackle": {
                            "_command": "track",
                            "_parameters": {}
                        }
                    }
                    """)
                    expect(result).to(beNil())
                    expect(mock.trackWithEventRef.invokations().count) == 0
                    expect(mock.trackWithEventUserIdRef.invokations().count) == 0
                    expect(mock.trackWithEventUserRef.invokations().count) == 0
                }
            }
            
            describe("remote config") {
                context("string type") {
                    it("happy case") {
                        let remoteConfig = MockRemoteConfig()
                        remoteConfig.config["string"] = "abcd1234"
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "string",
                                    "valueType": "string",
                                    "defaultValue": "foo"
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(result) == "abcd1234"
                    }
                    it("default value return case") {
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "string",
                                    "valueType": "string",
                                    "defaultValue": "foo"
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(result) == "foo"
                    }
                    it("invalid parameters case") {
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "string",
                                    "valueType": "string"
                                }
                            }
                        }
                        """)
                        expect(result).to(beNil())
                    }
                }
                context("number") {
                    it("happy case") {
                        let remoteConfig = MockRemoteConfig()
                        remoteConfig.config["number"] = 1234.5678
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "number",
                                    "valueType": "number",
                                    "defaultValue": 0
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(result) == "1234.5678"
                    }
                    it("default value return case") {
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "number",
                                    "valueType": "number",
                                    "defaultValue": 123
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(result) == "123.0"
                    }
                    it("invalid parameters case") {
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "number",
                                    "valueType": "number"
                                }
                            }
                        }
                        """)
                        expect(result).to(beNil())
                    }
                }
                context("boolean") {
                    it("happy case") {
                        let remoteConfig = MockRemoteConfig()
                        remoteConfig.config["boolean"] = true
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "boolean",
                                    "valueType": "boolean",
                                    "defaultValue": false
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(result) == "true"
                    }
                    it("default value return case") {
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "boolean",
                                    "valueType": "boolean",
                                    "defaultValue": false
                                }
                            }
                        }
                        """)
                        expect(result).notTo(beNil())
                        expect(result) == "false"
                    }
                    it("invalid parameters case") {
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let result = HackleBridge.invoke(app: mock, string: """
                        {
                            "_hackle": {
                                "_command": "remoteConfig",
                                "_parameters": {
                                    "key": "boolean",
                                    "valueType": "boolean"
                                }
                            }
                        }
                        """)
                        expect(result).to(beNil())
                    }
                }
            }
            it("show user explorer") {
                let mock = MockHackleApp()
                let result = HackleBridge.invoke(app: mock, string: """
                {
                    "_hackle": {
                        "_command": "showUserExplorer"
                    }
                }
                """)
                expect(result).to(beNil())
                expect(mock.showUserExplorerRef.invokations().count) == 1
            }
            it("hide user explorer") {
                let mock = MockHackleApp()
                let result = HackleBridge.invoke(app: mock, string: """
                {
                    "_hackle": {
                        "_command": "hideUserExplorer"
                    }
                }
                """)
                expect(result).to(beNil())
                expect(mock.hideUserExplorerRef.invokations().count) == 1
            }
        }
    }
}
