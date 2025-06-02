import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class HackleBridgeSpec : QuickSpec {
    
    func createJsonString(command: String, parameters: [String: Any]? = nil) -> String {
        return [
            "_hackle": [
                "command": command,
                "parameters": parameters ?? nil
            ] as [String : Any?]
        ].toJson() ?? ""
    }
    
    override func spec() {
        it("is invocable string") {
            let mock = MockHackleApp()
            let bridge = HackleBridge(app: mock)
            expect(bridge.isInvocableString(string: "{\"_hackle\":{\"command\":\"foo\"}}")) == true
            expect(bridge.isInvocableString(string: "{\"_hackle\":{\"command\":\"\"}}")) == false
            expect(bridge.isInvocableString(string: "{\"_hackle\":\"\"}}")) == false
            expect(bridge.isInvocableString(string: "{\"_hackle\":{}}}")) == false
            expect(bridge.isInvocableString(string: "{\"something\":{\"command\":\"\"}}")) == false
            expect(bridge.isInvocableString(string: "{")) == false
            expect(bridge.isInvocableString(string: "")) == false
        }
        describe("invoke") {
            it("get session id") {
                let sessionId = "1234567890.abcdefgh"
                let mock = MockHackleApp(sessonId: sessionId)
                let bridge = HackleBridge(app: mock)
                let jsonString = self.createJsonString(command: "getSessionId")
                let result = bridge.invoke(string: jsonString)
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"] as? String) == sessionId
            }
            it("get user") {
                let user = HackleUserBuilder()
                    .id("myid")
                    .userId("1234")
                    .deviceId("abcd1234")
                    .identifier("foo", "bar")
                    .property("bar", "foo")
                    .build()
                let mock = MockHackleApp(user: user)
                let bridge = HackleBridge(app: mock)
                let jsonString = self.createJsonString(command: "getUser")
                let result = bridge.invoke(string: jsonString)
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                
                let data = dict["data"] as! [String: Any]
                expect(data["id"] as? String) == user.id
                expect(data["userId"] as? String) == user.userId
                expect(data["deviceId"] as? String) == user.deviceId
                
                let identifiers = data["identifiers"] as! [String: String]
                expect(identifiers.count) == 1
                expect(identifiers["foo"]) == "bar"
                
                let properties = data["properties"] as! [String: Any]
                expect(properties.count) == 1
                expect(properties["bar"] as? String) == "foo"
                expect(mock.user.id) == user.id
                expect(mock.user.userId) == user.userId
                expect(mock.user.deviceId) == user.deviceId
                expect(mock.user.identifiers["foo"]) == "bar"
                expect(mock.user.properties["bar"] as? String) == "foo"
            }
            context("set user") {
                it("happy case") {
                    let parameters = [
                        "user": [
                            "id": "foo",
                            "userId": "bar",
                            "identifiers": [
                                "foobar": "foofoo",
                                "foobar2": "barbar"
                            ],
                            "properties": [
                                "null": nil,
                                "number": 123,
                                "string": "text",
                                "array": [123, "123", nil] as [Any?],
                                "map": ["key": "value"]
                            ] as [String : Any?]
                        ] as [String : Any]
                    ]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "setUser", parameters: parameters)
                    let result = bridge.invoke(string: jsonString)
                    
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
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.user.id) == "foo"
                    expect(mock.user.userId) == "bar"
                    expect(mock.user.identifiers["foobar"]) == "foofoo"
                    expect(mock.user.identifiers["foobar2"]) == "barbar"
                    expect(mock.user.properties["null"]).to(beNil())
                    expect(mock.user.properties["number"] as? Double) == 123.0
                    expect(mock.user.properties["string"] as? String) == "text"
                    expect((mock.user.properties["array"] as? [Any?])?.count) == 2
                    expect(mock.user.properties["map"] as? [String: String]).to(beNil())
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "setUser", parameters: [:])
                    let result = bridge.invoke(string: jsonString)
                    
                    expect(mock.setUserRef.invokations().count) == 0
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            context("set user id") {
                it("happy case") {
                    let parameters = ["userId": "abcd1234"]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "setUserId", parameters: parameters)
                    let result = bridge.invoke(string: jsonString)
                    
                    expect(mock.setUserIdRef.invokations().count) == 1
                    expect(mock.setUserIdRef.firstInvokation().arguments) == "abcd1234"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.user.userId) == "abcd1234"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "setUserId", parameters: [:])
                    let result = bridge.invoke(string: jsonString)
                    
                    expect(mock.setUserIdRef.invokations().count) == 0
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            context("set device id") {
                it("happy case") {
                    let parameters = ["deviceId": "abcd1234"]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "setDeviceId", parameters: parameters)
                    let result = bridge.invoke(string: jsonString)
                    
                    expect(mock.setDeviceIdRef.invokations().count) == 1
                    expect(mock.setDeviceIdRef.firstInvokation().arguments) == "abcd1234"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.user.deviceId) == "abcd1234"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "setDeviceId", parameters: [:])
                    let result = bridge.invoke(string: jsonString)
                    
                    expect(mock.setDeviceIdRef.invokations().count) == 0
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            context("set user property") {
                it("happy case") {
                    let parameters = [
                        "key": "foo",
                        "value": "bar",
                    ]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "setUserProperty", parameters: parameters)
                    let result = bridge.invoke(string: jsonString)
                    
                    expect(mock.setUserPropertyRef.invokations().count) == 1
                    expect(mock.setUserPropertyRef.firstInvokation().arguments.0) == "foo"
                    expect(mock.setUserPropertyRef.firstInvokation().arguments.1 as? String) == "bar"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.user.properties["foo"] as? String) == "bar"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "setUserProperty", parameters: [:])
                    let result = bridge.invoke(string: jsonString)

                    expect(mock.setUserPropertyRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            context("update user properties") {
                it("happy case") {
                    let parameters = [
                        "operations": [
                            "$set": [
                                "null": nil,
                                "number": 123,
                                "string": "text",
                                "array": [123, "123", nil] as [Any?],
                                "map": ["foo": "bar"]
                            ] as [String : Any?],
                            "$setOnce": [
                                "foo": "bar"
                            ]
                        ]
                    ]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "updateUserProperties", parameters: parameters)
                    let result = bridge.invoke(string: jsonString)
                    
                    expect(mock.updateUserPropertiesRef.invokations().count) == 1
                    let arguments = mock.updateUserPropertiesRef.firstInvokation().arguments.asDictionary()
                    
                    let set = arguments[PropertyOperation.set]!
                    expect(set.count) == 3
                    expect(set["number"] as? Double) == 123.0
                    expect(set["string"] as? String) == "text"
                    
                    let array = set["array"] as! Array<Any>
                    expect(array.count) == 2
                    expect(array[0] as? Double) == 123.0
                    expect(array[1] as? String) == "123"
                    
                    let setOnce = arguments[PropertyOperation.setOnce]!
                    expect(setOnce["foo"] as? String) == "bar"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "updateUserProperties", parameters: [:])
                    let result = bridge.invoke(string: jsonString)

                    expect(mock.updateUserPropertiesRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            it("reset user") {
                let mock = MockHackleApp()
                let bridge = HackleBridge(app: mock)
                let jsonString = self.createJsonString(command: "resetUser", parameters: [:])
                let result = bridge.invoke(string: jsonString)
                
                expect(mock.resetUserRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
                expect(mock.user.id).to(beNil())
                expect(mock.user.userId).to(beNil())
                expect(mock.user.deviceId).to(beNil())
                expect(mock.user.identifiers).to(beEmpty())
                expect(mock.user.properties).to(beEmpty())
            }
            it("setPhoneNumber") {
                let mock = MockHackleApp()
                let bridge = HackleBridge(app: mock)
                let jsonString = self.createJsonString(command: "setPhoneNumber", parameters: ["phoneNumber": "+821012345678"])
                let result = bridge.invoke(string: jsonString)
                
                expect(mock.setPhoneNumberRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
            }
            it("unsetPhoneNumber") {
                let mock = MockHackleApp()
                let bridge = HackleBridge(app: mock)
                let jsonString = self.createJsonString(command: "unsetPhoneNumber")
                let result = bridge.invoke(string: jsonString)
                
                expect(mock.unsetPhoneNumberRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
            }
            describe("variation") {
                context("normal") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D"
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        
                        every(mock.variationRef).returns("C")
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.variationRef.invokations().count) == 1
                        
                        let arguments = mock.variationRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = ["experimentKey": 123] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationRef).returns("A")
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.variationRef.invokations().count) == 1
                        
                        let arguments = mock.variationRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "A"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "A"
                    }
                }
                context("with user string") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D",
                            "user": "abcd1234"
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationRef).returns("C")
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserIdRef.invokations().count) == 1
                        expect(mock.variationRef.invokations().count) == 1
                        
                        let arguments = mock.variationRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                        expect(mock.user.userId) == "abcd1234"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": "abcd1234"
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationRef).returns("A")
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserIdRef.invokations().count) == 1
                        expect(mock.variationRef.invokations().count) == 1
                        
                        let arguments = mock.variationRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "A"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "A"
                        expect(mock.user.userId) == "abcd1234"
                    }
                }
                context("with user object") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D",
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationRef).returns("C")
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserRef.invokations().count) == 1
                        expect(mock.variationRef.invokations().count) == 1
                        
                        let arguments = mock.variationRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                        expect(mock.user.id) == "foo"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationRef).returns("A")
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserRef.invokations().count) == 1
                        expect(mock.variationRef.invokations().count) == 1
                        
                        let arguments = mock.variationRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "A"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "A"
                        expect(mock.user.id) == "foo"
                    }
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "variation", parameters: [:])
                    let result = bridge.invoke(string: jsonString)

                    expect(mock.variationRef.invokations().count) == 0
                    expect(mock.variationWithUserIdRef.invokations().count) == 0
                    expect(mock.variationWithUserRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            describe("variation detail") {
                context("normal") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D"
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["variation"] as? String) == "C"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "A"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["experiment"]).to(beNil())
                        expect(data["variation"] as? String) == "A"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                    }
                }
                context("with user string") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D",
                            "user": "abcd1234"
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserIdRef.invokations().count) == 1
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["experiment"]).to(beNil())
                        expect(data["variation"] as? String) == "C"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                        expect(mock.user.userId) == "abcd1234"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": "abcd1234"
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserIdRef.invokations().count) == 1
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "A"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["experiment"]).to(beNil())
                        expect(data["variation"] as? String) == "A"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                        expect(mock.user.userId) == "abcd1234"
                    }
                }
                context("with user object") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D",
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserRef.invokations().count) == 1
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["experiment"]).to(beNil())
                        expect(data["variation"] as? String) == "C"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                        expect(mock.user.id) == "foo"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserRef.invokations().count) == 1
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1) == "A"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["experiment"]).to(beNil())
                        expect(data["variation"] as? String) == "A"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                        expect(mock.user.id) == "foo"
                    }
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "variationDetail", parameters: [:])
                    let result = bridge.invoke(string: jsonString)

                    expect(mock.variationDetailRef.invokations().count) == 0
                    expect(mock.variationDetailWithUserIdRef.invokations().count) == 0
                    expect(mock.variationDetailWithUserRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            describe("is feature on") {
                it("happy case") {
                    let parameters = [
                        "featureKey": 123
                    ] as [String : Any]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(mock.isFeatureOnRef)
                        .returns(true)
                        
                    let result = bridge.invoke(string: jsonString)
                    expect(mock.isFeatureOnRef.invokations().count) == 1
                        
                    let arguments = mock.isFeatureOnRef.firstInvokation().arguments
                    expect(arguments) == 123
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                }
                it("with user string case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": "abcd1234"
                    ] as [String : Any]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(mock.isFeatureOnRef)
                        .returns(true)
                        
                    let result = bridge.invoke(string: jsonString)
                    expect(mock.setUserIdRef.invokations().count) == 1
                    expect(mock.isFeatureOnRef.invokations().count) == 1
                        
                    let arguments = mock.isFeatureOnRef.firstInvokation().arguments
                    expect(arguments) == 123
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                    expect(mock.user.userId) == "abcd1234"
                }
                it("with user object case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": ["id": "foo"]
                    ] as [String : Any]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(mock.isFeatureOnRef)
                        .returns(true)
                        
                    let result = bridge.invoke(string: jsonString)
                    expect(mock.setUserRef.invokations().count) == 1
                    expect(mock.isFeatureOnRef.invokations().count) == 1
                        
                    let arguments = mock.isFeatureOnRef.firstInvokation().arguments
                    expect(arguments) == 123
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                    expect(mock.user.id) == "foo"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: [:])
                    let result = bridge.invoke(string: jsonString)

                    expect(mock.isFeatureOnRef.invokations().count) == 0
                    expect(mock.isFeatureOnWithUserIdRef.invokations().count) == 0
                    expect(mock.isFeatureOnWithUserRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            describe("feature flag detail") {
                it("happy case") {
                    let parameters = [
                        "featureKey": 123
                    ] as [String : Any]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = bridge.invoke(string: jsonString)
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments) == 123
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    
                    let data = dict["data"] as! [String: Any]
                    expect(data["featureFlag"]).to(beNil())
                    expect(data["isOn"] as? Bool) == true
                    expect(data["reason"] as? String) == "DEFAULT_RULE"
                    
                    let config = data["config"] as! [String: Any]
                    expect(config["parameters"]).toNot(beNil())
                }
                it("with user string case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": "abcd1234"
                    ] as [String : Any]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = bridge.invoke(string: jsonString)
                    expect(mock.setUserIdRef.invokations().count) == 1
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments) == 123
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    
                    let data = dict["data"] as! [String: Any]
                    expect(data["featureFlag"]).to(beNil())
                    expect(data["isOn"] as? Bool) == true
                    expect(data["reason"] as? String) == "DEFAULT_RULE"
                    
                    let config = data["config"] as! [String: Any]
                    expect(config["parameters"]).toNot(beNil())
                    expect(mock.user.userId) == "abcd1234"
                }
                it("with user case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": ["id": "foo"]
                    ] as [String : Any]
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = bridge.invoke(string: jsonString)
                    expect(mock.setUserRef.invokations().count) == 1
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments) == 123
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    
                    let data = dict["data"] as! [String: Any]
                    expect(data["featureFlag"]).to(beNil())
                    expect(data["isOn"] as? Bool) == true
                    expect(data["reason"] as? String) == "DEFAULT_RULE"
                    
                    let config = data["config"] as! [String: Any]
                    expect(config["parameters"]).toNot(beNil())
                    expect(mock.user.id) == "foo"
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: [:])
                    let result = bridge.invoke(string: jsonString)

                    expect(mock.featureFlagDetailRef.invokations().count) == 0
                    expect(mock.featureFlagDetailWithUserIdRef.invokations().count) == 0
                    expect(mock.featureFlagDetailWithUserRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            describe("track") {
                context("with event string") {
                    it("happy case") {
                        let parameters = [
                            "event": "helloHackle"
                        ]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = bridge.invoke(string: jsonString)
                        
                        expect(mock.trackWithEventKeyRef.invokations().count) == 1
                        
                        let arguments = mock.trackWithEventKeyRef.firstInvokation().arguments
                        expect(arguments) == "helloHackle"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                    }
                    it("with user string") {
                        let parameters = [
                            "event": "helloHackle",
                            "user": "foo"
                        ]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserIdRef.invokations().count) == 1
                        expect(mock.trackWithEventKeyRef.invokations().count) == 1
                        
                        let arguments = mock.trackWithEventKeyRef.firstInvokation().arguments
                        expect(arguments) == "helloHackle"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.user.userId) == "foo"
                    }
                    it("with user object") {
                        let parameters = [
                            "event": "helloHackle",
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserRef.invokations().count) == 1
                        expect(mock.trackWithEventKeyRef.invokations().count) == 1
                        
                        let arguments = mock.trackWithEventKeyRef.firstInvokation().arguments
                        expect(arguments) == "helloHackle"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.user.id) == "foo"
                    }
                }
                context("with event object") {
                    it("happy case") {
                        let parameters = [
                            "event": [
                                "key": "helloHackle",
                                "value": 1234,
                                "properties": [
                                    "null": nil,
                                    "number": 123,
                                    "string": "text",
                                    "array": [123, "123", nil] as [Any?],
                                    "map": ["key": "value"]
                                ] as [String : Any?]
                            ] as [String : Any]
                        ]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.trackWithEventRef.invokations().count) == 1
                        
                        let arguments = mock.trackWithEventRef.firstInvokation().arguments
                        expect(arguments.key) == "helloHackle"
                        expect(arguments.value) == 1234
                        expect(arguments.properties!.count) == 3
                        expect(arguments.properties!["number"] as? Double) == 123.0
                        expect(arguments.properties!["string"] as? String) == "text"
                        
                        let array = arguments.properties!["array"] as! Array<Any>
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                    }
                    it("with user string") {
                        let parameters = [
                            "event": [
                                "key": "helloHackle",
                                "value": 1234,
                                "properties": [
                                    "null": nil,
                                    "number": 123,
                                    "string": "text",
                                    "array": [123, "123", nil] as [Any?],
                                    "map": ["key": "value"]
                                ] as [String : Any?]
                            ] as [String : Any],
                            "user": "abcd1234"
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserIdRef.invokations().count) == 1
                        expect(mock.trackWithEventRef.invokations().count) == 1
                        
                        let arguments = mock.trackWithEventRef.firstInvokation().arguments
                        expect(arguments.key) == "helloHackle"
                        expect(arguments.value) == 1234
                        expect(arguments.properties!.count) == 3
                        expect(arguments.properties!["number"] as? Double) == 123.0
                        expect(arguments.properties!["string"] as? String) == "text"
                        
                        let array = arguments.properties!["array"] as! Array<Any>
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.user.userId) == "abcd1234"
                    }
                    it("with user object") {
                        let parameters = [
                            "event": [
                                "key": "helloHackle",
                                "value": 1234,
                                "properties": [
                                    "null": nil,
                                    "number": 123,
                                    "string": "text",
                                    "array": [123, "123", nil] as [Any?],
                                    "map": ["key": "value"]
                                ] as [String : Any?]
                            ] as [String : Any],
                            "user": ["id":"abcd1234"]
                        ] as [String : Any]
                        let mock = MockHackleApp()
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        
                        let result = bridge.invoke(string: jsonString)
                        expect(mock.setUserRef.invokations().count) == 1
                        expect(mock.trackWithEventRef.invokations().count) == 1
                        
                        let arguments = mock.trackWithEventRef.firstInvokation().arguments
                        expect(arguments.key) == "helloHackle"
                        expect(arguments.value) == 1234
                        expect(arguments.properties!.count) == 3
                        expect(arguments.properties!["number"] as? Double) == 123.0
                        expect(arguments.properties!["string"] as? String) == "text"
                        
                        let array = arguments.properties!["array"] as! Array<Any>
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.user.id) == "abcd1234"
                    }
                }
                it("invalid parameters case") {
                    let mock = MockHackleApp()
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "track", parameters: [:])
                    let result = bridge.invoke(string: jsonString)

                    expect(mock.trackWithEventRef.invokations().count) == 0
                    expect(mock.trackWithEventUserIdRef.invokations().count) == 0
                    expect(mock.trackWithEventUserRef.invokations().count) == 0
                    expect(mock.trackWithEventKeyRef.invokations().count) == 0
                    expect(mock.trackWithEventKeyUserIdRef.invokations().count) == 0
                    expect(mock.trackWithEventKeyUserRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            describe("remote config") {
                context("normal") {
                    it("number case") {
                        let parameters = [
                            "key": "number",
                            "valueType": "number",
                            "defaultValue": 0
                        ] as [String : Any]
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let bridge = HackleBridge(app: mock)
                        remoteConfig.config["number"] = 1234.5678
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = bridge.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "1234.5678"
                    }
                    it("number default value return case") {
                        let parameters = [
                            "key": "number",
                            "valueType": "number",
                            "defaultValue": 0
                        ] as [String : Any]
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = bridge.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "0.0"
                    }
                    it("boolean case") {
                        let parameters = [
                            "key": "bool",
                            "valueType": "boolean",
                            "defaultValue": false
                        ] as [String : Any]
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let bridge = HackleBridge(app: mock)
                        remoteConfig.config["bool"] = true
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = bridge.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "true"
                    }
                    it("boolean default value return case") {
                        let parameters = [
                            "key": "bool",
                            "valueType": "boolean",
                            "defaultValue": true
                        ] as [String : Any]
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = bridge.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "true"
                    }
                    it("string case") {
                        let parameters = [
                            "key": "string",
                            "valueType": "string",
                            "defaultValue": "default"
                        ] as [String : Any]
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let bridge = HackleBridge(app: mock)
                        remoteConfig.config["string"] = "abcd1234"
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = bridge.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "abcd1234"
                    }
                    it("string default value return case") {
                        let parameters = [
                            "key": "string",
                            "valueType": "string",
                            "defaultValue": "default"
                        ] as [String : Any]
                        let remoteConfig = MockRemoteConfig()
                        let mock = MockHackleApp(remoteConfig: remoteConfig)
                        let bridge = HackleBridge(app: mock)
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = bridge.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "default"
                    }
                    context("with user string") {
                        it("number case") {
                            let parameters = [
                                "key": "number",
                                "valueType": "number",
                                "defaultValue": 0,
                                "user": "abcd1234"
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            remoteConfig.config["number"] = 1234.5678
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserIdRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "1234.5678"
                            expect(mock.user.userId) == "abcd1234"
                        }
                        it("number default value return case") {
                            let parameters = [
                                "key": "number",
                                "valueType": "number",
                                "defaultValue": 0,
                                "user": "abcd1234"
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserIdRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "0.0"
                            expect(mock.user.userId) == "abcd1234"
                        }
                        it("boolean case") {
                            let parameters = [
                                "key": "bool",
                                "valueType": "boolean",
                                "defaultValue": false,
                                "user": "abcd1234"
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            remoteConfig.config["bool"] = true
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserIdRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "true"
                            expect(mock.user.userId) == "abcd1234"
                        }
                        it("boolean default value return case") {
                            let parameters = [
                                "key": "bool",
                                "valueType": "boolean",
                                "defaultValue": true,
                                "user": "abcd1234"
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserIdRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "true"
                            expect(mock.user.userId) == "abcd1234"
                        }
                        it("string case") {
                            let parameters = [
                                "key": "string",
                                "valueType": "string",
                                "defaultValue": "default",
                                "user": "abcd1234"
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            remoteConfig.config["string"] = "helloHackle"
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserIdRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "helloHackle"
                            expect(mock.user.userId) == "abcd1234"
                        }
                        it("string default value return case") {
                            let parameters = [
                                "key": "string",
                                "valueType": "string",
                                "defaultValue": "default",
                                "user": "abcd1234"
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserIdRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "default"
                            expect(mock.user.userId) == "abcd1234"
                        }
                    }
                    context("with user object") {
                        it("number case") {
                            let parameters = [
                                "key": "number",
                                "valueType": "number",
                                "defaultValue": 0,
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            remoteConfig.config["number"] = 1234.5678
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "1234.5678"
                            expect(mock.user.id) == "abcd1234"
                        }
                        it("number default value return case") {
                            let parameters = [
                                "key": "number",
                                "valueType": "number",
                                "defaultValue": 0,
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "0.0"
                            expect(mock.user.id) == "abcd1234"
                        }
                        it("boolean case") {
                            let parameters = [
                                "key": "bool",
                                "valueType": "boolean",
                                "defaultValue": false,
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            remoteConfig.config["bool"] = true
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "true"
                            expect(mock.user.id) == "abcd1234"
                        }
                        it("boolean default value return case") {
                            let parameters = [
                                "key": "bool",
                                "valueType": "boolean",
                                "defaultValue": true,
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "true"
                            expect(mock.user.id) == "abcd1234"
                        }
                        it("string case") {
                            let parameters = [
                                "key": "string",
                                "valueType": "string",
                                "defaultValue": "default",
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            remoteConfig.config["string"] = "helloHackle"
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "helloHackle"
                            expect(mock.user.id) == "abcd1234"
                        }
                        it("string default value return case") {
                            let parameters = [
                                "key": "string",
                                "valueType": "string",
                                "defaultValue": "default",
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            let remoteConfig = MockRemoteConfig()
                            let mock = MockHackleApp(remoteConfig: remoteConfig)
                            let bridge = HackleBridge(app: mock)
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            
                            let result = bridge.invoke(string: jsonString)
                            expect(mock.setUserRef.invokations().count) == 1
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "default"
                            expect(mock.user.id) == "abcd1234"
                        }
                    }
                }
                it("invalid parameters case") {
                    let remoteConfig = MockRemoteConfig()
                    let mock = MockHackleApp(remoteConfig: remoteConfig)
                    let bridge = HackleBridge(app: mock)
                    let jsonString = self.createJsonString(command: "remoteConfig", parameters: [:])
                    let result = bridge.invoke(string: jsonString)
                    
                    expect(mock.remoteConfigWithUserRef.invokations().count) == 0
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            describe("show user explorer") {
                let mock = MockHackleApp()
                let bridge = HackleBridge(app: mock)
                let jsonString = self.createJsonString(command: "showUserExplorer", parameters: [:])
                let result = bridge.invoke(string: jsonString)
                
                expect(mock.showUserExplorerRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
            }
            describe("hide user explorer") {
                let mock = MockHackleApp()
                let bridge = HackleBridge(app: mock)
                let jsonString = self.createJsonString(command: "hideUserExplorer", parameters: [:])
                let result = bridge.invoke(string: jsonString)

                expect(mock.hideUserExplorerRef.invokations().count) == 1

                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
            }
        }
    }
}
