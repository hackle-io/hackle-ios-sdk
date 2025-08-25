import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class HackleInvocationSpec : QuickSpec {
    func createJsonString(command: String, parameters: [String: Any?]? = nil) -> String {
        return [
            "_hackle": [
                "command": command,
                "parameters": parameters ?? nil,
                "browserProperties": [
                    "mock": "mocks"
                ]
            ] as [String : Any?]
        ].toJson() ?? ""
    }
    
    override func spec() {
        var mock: MockHackleAppCore!
        var invocation: DefaultHackleInvocator!
        
        beforeEach {
            mock = MockHackleAppCore()
            invocation = DefaultHackleInvocator(hackleAppCore: mock)
        }
        
        it("is invocable string") {
            expect(invocation.isInvocableString(string: "{\"_hackle\":{\"command\":\"foo\"}}")) == true
            expect(invocation.isInvocableString(string: "{\"_hackle\":{\"command\":\"\"}}")) == false
            expect(invocation.isInvocableString(string: "{\"_hackle\":\"\"}}")) == false
            expect(invocation.isInvocableString(string: "{\"_hackle\":{}}}")) == false
            expect(invocation.isInvocableString(string: "{\"something\":{\"command\":\"\"}}")) == false
            expect(invocation.isInvocableString(string: "{")) == false
            expect(invocation.isInvocableString(string: "")) == false
        }
        describe("invoke") {
            it("get session id") {
                let sessionId = "1234567890.abcdefgh"
                mock.sessionId = sessionId
                
                let jsonString = self.createJsonString(command: "getSessionId")
                let result = invocation.invoke(string: jsonString)
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
                mock.user = user
                
                let jsonString = self.createJsonString(command: "getUser")
                let result = invocation.invoke(string: jsonString)
                
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

                    let jsonString = self.createJsonString(command: "setUser", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.setUserRef.invokations().count) == 1
                    let arguments = mock.setUserRef.firstInvokation().arguments.0
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
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "setUser", parameters: [:])
                    let result = invocation.invoke(string: jsonString)
                    
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
                    let jsonString = self.createJsonString(command: "setUserId", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.setUserIdRef.invokations().count) == 1
                    expect(mock.setUserIdRef.firstInvokation().arguments.0) == "abcd1234"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "setUserId", parameters: [:])
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.setUserIdRef.invokations().count) == 0
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
                it("nil case") {
                    let jsonString = self.createJsonString(command: "setUserId", parameters: ["userId":nil])
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.setUserIdRef.invokations().count) == 1
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            context("set device id") {
                it("happy case") {
                    let parameters = ["deviceId": "abcd1234"]
                    let jsonString = self.createJsonString(command: "setDeviceId", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.setDeviceIdRef.invokations().count) == 1
                    expect(mock.setDeviceIdRef.firstInvokation().arguments.0) == "abcd1234"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "setDeviceId", parameters: [:])
                    let result = invocation.invoke(string: jsonString)
                    
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
                    let jsonString = self.createJsonString(command: "setUserProperty", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.updateUserPropertiesRef.invokations().count) == 1
                    let arguments = mock.updateUserPropertiesRef.firstInvokation().arguments.0.asDictionary()
                    let set = arguments[PropertyOperation.set]!
                    expect(set.count) == 1
                    expect(set["foo"] as? String) == "bar"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "setUserProperty", parameters: [:])
                    let result = invocation.invoke(string: jsonString)

                    expect(mock.updateUserPropertiesRef.invokations().count) == 0

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
                    let jsonString = self.createJsonString(command: "updateUserProperties", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.updateUserPropertiesRef.invokations().count) == 1
                    let arguments = mock.updateUserPropertiesRef.firstInvokation().arguments.0.asDictionary()
                    
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
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "updateUserProperties", parameters: [:])
                    let result = invocation.invoke(string: jsonString)

                    expect(mock.updateUserPropertiesRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
            context("update subscriptions") {
                let parameters = [
                    "operations": [
                        "$global": "SUBSCRIBED",
                        "$information": "UNSUBSCRIBED",
                        "$marketing": "UNKNOWN",
                        "chat": "SUBSCRIBED"
                    ]
                ]
                
                it("push") {
                    let jsonString = self.createJsonString(command: "updatePushSubscriptions", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.updatePushSubscriptionsRef.invokations().count) == 1
                    
                    let arguments = mock.updatePushSubscriptionsRef.firstInvokation().arguments
                    expect(arguments.0.count) == 4
                    
                    let mockEvent = arguments.0.toEvent(key: "mock")
                    expect(mockEvent.key) == "mock"
                    expect(mockEvent.properties?["$global"] as? String) == "SUBSCRIBED"
                    expect(mockEvent.properties?["$information"] as? String) == "UNSUBSCRIBED"
                    expect(mockEvent.properties?["$marketing"] as? String) == "UNKNOWN"
                    expect(mockEvent.properties?["chat"] as? String) == "SUBSCRIBED"

                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                
                it("sms") {
                    let jsonString = self.createJsonString(command: "updateSmsSubscriptions", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.updateSmsSubscriptionsRef.invokations().count) == 1
                    
                    let arguments = mock.updateSmsSubscriptionsRef.firstInvokation().arguments
                    expect(arguments.0.count) == 4
                    
                    let mockEvent = arguments.0.toEvent(key: "mock")
                    expect(mockEvent.key) == "mock"
                    expect(mockEvent.properties?["$global"] as? String) == "SUBSCRIBED"
                    expect(mockEvent.properties?["$information"] as? String) == "UNSUBSCRIBED"
                    expect(mockEvent.properties?["$marketing"] as? String) == "UNKNOWN"
                    expect(mockEvent.properties?["chat"] as? String) == "SUBSCRIBED"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                
                it("kakao") {
                    let jsonString = self.createJsonString(command: "updateKakaoSubscriptions", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.updateKakaoSubscriptionsRef.invokations().count) == 1
                    
                    let arguments = mock.updateKakaoSubscriptionsRef.firstInvokation().arguments
                    expect(arguments.0.count) == 4
                    
                    let mockEvent = arguments.0.toEvent(key: "mock")
                    expect(mockEvent.key) == "mock"
                    expect(mockEvent.properties?["$global"] as? String) == "SUBSCRIBED"
                    expect(mockEvent.properties?["$information"] as? String) == "UNSUBSCRIBED"
                    expect(mockEvent.properties?["$marketing"] as? String) == "UNKNOWN"
                    expect(mockEvent.properties?["chat"] as? String) == "SUBSCRIBED"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
            }
            it("reset user") {
                let jsonString = self.createJsonString(command: "resetUser", parameters: [:])
                let result = invocation.invoke(string: jsonString)
                
                expect(mock.resetUserRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
                expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
            }
            it("setPhoneNumber") {
                let jsonString = self.createJsonString(command: "setPhoneNumber", parameters: ["phoneNumber": "+821012345678"])
                let result = invocation.invoke(string: jsonString)
                
                expect(mock.setPhoneNumberRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
                expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
            }
            it("unsetPhoneNumber") {
                let jsonString = self.createJsonString(command: "unsetPhoneNumber")
                let result = invocation.invoke(string: jsonString)
                
                expect(mock.unsetPhoneNumberRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
                expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
            }
            describe("variation") {
                context("normal") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D"
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1).to(beNil())
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = ["experimentKey": 123] as [String : Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1).to(beNil())
                        expect(arguments.2) == "A"
                        
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
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "abcd1234"
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": "abcd1234"
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "abcd1234"
                        expect(arguments.2) == "A"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "A"
                    }
                }
                context("with user object") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D",
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "foo"
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "foo"
                        expect(arguments.2) == "A"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "A"
                    }
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "variation", parameters: [:])
                    let result = invocation.invoke(string: jsonString)

                    expect(mock.variationDetailRef.invokations().count) == 0

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
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1).to(beNil())
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["variation"] as? String) == "C"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1).to(beNil())
                        expect(arguments.2) == "A"
                        
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
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "abcd1234"
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["experiment"]).to(beNil())
                        expect(data["variation"] as? String) == "C"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": "abcd1234"
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "abcd1234"
                        expect(arguments.2) == "A"
                        
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
                context("with user object") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D",
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "foo"
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        
                        let data = dict["data"] as! [String: Any]
                        expect(data["experiment"]).to(beNil())
                        expect(data["variation"] as? String) == "C"
                        expect(data["reason"] as? String) == "DEFAULT_RULE"
                        
                        let config = data["config"] as! [String: Any]
                        expect(config["parameters"]).toNot(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(mock.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = invocation.invoke(string: jsonString)
                        expect(mock.variationDetailRef.invokations().count) == 1
                        
                        let arguments = mock.variationDetailRef.firstInvokation().arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "foo"
                        expect(arguments.2) == "A"
                        
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
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "variationDetail", parameters: [:])
                    let result = invocation.invoke(string: jsonString)

                    expect(mock.variationDetailRef.invokations().count) == 0

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
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = invocation.invoke(string: jsonString)
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("with user string case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": "abcd1234"
                    ] as [String : Any]
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = invocation.invoke(string: jsonString)
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                    expect(arguments.1?.id) == "abcd1234"
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("with user object case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": ["id": "foo"]
                    ] as [String : Any]
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = invocation.invoke(string: jsonString)
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                    expect(arguments.1?.id) == "foo"

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: [:])
                    let result = invocation.invoke(string: jsonString)

                    expect(mock.featureFlagDetailRef.invokations().count) == 0

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
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = invocation.invoke(string: jsonString)
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    
                    let data = dict["data"] as! [String: Any]
                    expect(data["featureFlag"]).to(beNil())
                    expect(data["isOn"] as? Bool) == true
                    expect(data["reason"] as? String) == "DEFAULT_RULE"
                    
                    let config = data["config"] as! [String: Any]
                    expect(config["parameters"]).toNot(beNil())
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("with user string case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": "abcd1234"
                    ] as [String : Any]
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = invocation.invoke(string: jsonString)
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                    expect(arguments.1?.id) == "abcd1234"
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    
                    let data = dict["data"] as! [String: Any]
                    expect(data["featureFlag"]).to(beNil())
                    expect(data["isOn"] as? Bool) == true
                    expect(data["reason"] as? String) == "DEFAULT_RULE"
                    
                    let config = data["config"] as! [String: Any]
                    expect(config["parameters"]).toNot(beNil())
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("with user case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": ["id": "foo"]
                    ] as [String : Any]
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(mock.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = invocation.invoke(string: jsonString)
                    expect(mock.featureFlagDetailRef.invokations().count) == 1
                        
                    let arguments = mock.featureFlagDetailRef.firstInvokation().arguments
                    expect(arguments.0) == 123
                    expect(arguments.1?.id) == "foo"

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    
                    let data = dict["data"] as! [String: Any]
                    expect(data["featureFlag"]).to(beNil())
                    expect(data["isOn"] as? Bool) == true
                    expect(data["reason"] as? String) == "DEFAULT_RULE"
                    
                    let config = data["config"] as! [String: Any]
                    expect(config["parameters"]).toNot(beNil())
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: [:])
                    let result = invocation.invoke(string: jsonString)

                    expect(mock.featureFlagDetailRef.invokations().count) == 0

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
                            "event": "abcd1234"
                        ]
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.trackRef.invokations().count) == 1
                        
                        let arguments = mock.trackRef.firstInvokation().arguments
                        expect(arguments.0.key) == "abcd1234"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("with user string") {
                        let parameters = [
                            "event": "abcd1234",
                            "user": "foo"
                        ]
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.trackRef.invokations().count) == 1
                        
                        let arguments = mock.trackRef.firstInvokation().arguments
                        expect(arguments.0.key) == "abcd1234"
                        expect(arguments.1?.id) == "foo"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("with user object") {
                        let parameters = [
                            "event": "abcd1234",
                            "user": ["id": "foo"]
                        ] as [String : Any]
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.trackRef.invokations().count) == 1
                        
                        let arguments = mock.trackRef.firstInvokation().arguments
                        expect(arguments.0.key) == "abcd1234"
                        expect(arguments.1?.id) == "foo"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                }
                context("with event object") {
                    it("happy case") {
                        let parameters = [
                            "event": [
                                "key": "foo",
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
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.trackRef.invokations().count) == 1
                        
                        let arguments = mock.trackRef.firstInvokation().arguments
                        expect(arguments.0.key) == "foo"
                        expect(arguments.0.value) == 1234
                        expect(arguments.0.properties!.count) == 3
                        expect(arguments.0.properties!["number"] as? Double) == 123.0
                        expect(arguments.0.properties!["string"] as? String) == "text"
                        
                        let array = arguments.0.properties!["array"] as! Array<Any>
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.0.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("with user string") {
                        let parameters = [
                            "event": [
                                "key": "foo",
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
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.trackRef.invokations().count) == 1
                        
                        let arguments = mock.trackRef.firstInvokation().arguments
                        expect(arguments.0.key) == "foo"
                        expect(arguments.0.value) == 1234
                        expect(arguments.0.properties!.count) == 3
                        expect(arguments.0.properties!["number"] as? Double) == 123.0
                        expect(arguments.0.properties!["string"] as? String) == "text"
                        expect(arguments.1?.id) == "abcd1234"
                        
                        let array = arguments.0.properties!["array"] as! Array<Any>
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.0.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("with user object") {
                        let parameters = [
                            "event": [
                                "key": "foo",
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
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.trackRef.invokations().count) == 1
                        
                        let arguments = mock.trackRef.firstInvokation().arguments
                        expect(arguments.0.key) == "foo"
                        expect(arguments.0.value) == 1234
                        expect(arguments.0.properties!.count) == 3
                        expect(arguments.0.properties!["number"] as? Double) == 123.0
                        expect(arguments.0.properties!["string"] as? String) == "text"
                        expect(arguments.1?.id) == "abcd1234"

                        let array = arguments.0.properties!["array"] as! Array<Any>
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.0.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "track", parameters: [:])
                    let result = invocation.invoke(string: jsonString)

                    expect(mock.trackRef.invokations().count) == 0

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
                        
                        every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234.5678), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? Double) == 1234.5678
                        expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("number default value return case") {
                        let parameters = [
                            "key": "number",
                            "valueType": "number",
                            "defaultValue": 0
                        ] as [String : Any]
                        every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "notnumber"), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? Double) == 0.0
                    }
                    it("boolean case") {
                        let parameters = [
                            "key": "bool",
                            "valueType": "boolean",
                            "defaultValue": false
                        ] as [String : Any]
                        every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? Bool) == true
                    }
                    it("boolean default value return case") {
                        let parameters = [
                            "key": "bool",
                            "valueType": "boolean",
                            "defaultValue": true
                        ] as [String : Any]
                        every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
                        expect(mock.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? Bool) == true
                    }
                    it("string case") {
                        let parameters = [
                            "key": "string",
                            "valueType": "string",
                            "defaultValue": "default"
                        ] as [String : Any]
                        every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "abcd1234"), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
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
                        every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = invocation.invoke(string: jsonString)
                        
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
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234.5678), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.userId) == "abcd1234"
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Double) == 1234.5678
                        }
                        it("number default value return case") {
                            let parameters = [
                                "key": "number",
                                "valueType": "number",
                                "defaultValue": 0,
                                "user": "abcd1234"
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "notnumber"), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.userId) == "abcd1234"
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Double) == 0.0
                        }
                        it("boolean case") {
                            let parameters = [
                                "key": "bool",
                                "valueType": "boolean",
                                "defaultValue": false,
                                "user": "abcd1234"
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.userId) == "abcd1234"
                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Bool) == true
                        }
                        it("boolean default value return case") {
                            let parameters = [
                                "key": "bool",
                                "valueType": "boolean",
                                "defaultValue": true,
                                "user": "abcd1234"
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.userId) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Bool) == true
                        }
                        it("string case") {
                            let parameters = [
                                "key": "string",
                                "valueType": "string",
                                "defaultValue": "default",
                                "user": "abcd1234"
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "abcd1234"), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.userId) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "abcd1234"
                        }
                        it("string default value return case") {
                            let parameters = [
                                "key": "string",
                                "valueType": "string",
                                "defaultValue": "default",
                                "user": "abcd1234"
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.userId) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "default"
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
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234.5678), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.id) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Double) == 1234.5678
                            expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                        }
                        it("number default value return case") {
                            let parameters = [
                                "key": "number",
                                "valueType": "number",
                                "defaultValue": 0,
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.id) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Double) == 0.0
                        }
                        it("boolean case") {
                            let parameters = [
                                "key": "bool",
                                "valueType": "boolean",
                                "defaultValue": false,
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.id) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Bool) == true
                        }
                        it("boolean default value return case") {
                            let parameters = [
                                "key": "bool",
                                "valueType": "boolean",
                                "defaultValue": true,
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.id) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Bool) == true
                        }
                        it("string case") {
                            let parameters = [
                                "key": "string",
                                "valueType": "string",
                                "defaultValue": "default",
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "abcd1234"), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.id) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "abcd1234"
                        }
                        it("string default value return case") {
                            let parameters = [
                                "key": "string",
                                "valueType": "string",
                                "defaultValue": "default",
                                "user": ["id": "abcd1234"]
                            ] as [String : Any]
                            every(mock.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = invocation.invoke(string: jsonString)
                            expect(mock.remoteConfigRef.invokations().count) == 1
                            let arguments = mock.remoteConfigRef.firstInvokation().arguments
                            expect(arguments.2?.id) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? String) == "default"
                        }
                    }
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "remoteConfig", parameters: [:])
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.remoteConfigRef.invokations().count) == 0
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
            }
			describe("set current screen") {
                it("happy case") {
                    let parameters: [String: Any] = [
                        "screenName": "main",
                        "className": "UIViewController"
                    ]
                    let jsonString = self.createJsonString(command: "setCurrentScreen", parameters: parameters)
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.setCurrentScreenRef.invokations().count) == 1
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(mock.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
            }
            describe("user explorer") {
                it("show") {
                    let jsonString = self.createJsonString(command: "showUserExplorer", parameters: [:])
                    let result = invocation.invoke(string: jsonString)
                    
                    expect(mock.showUserExplorerRef.invokations().count) == 1
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
                
                it("hide") {
                    let jsonString = self.createJsonString(command: "hideUserExplorer", parameters: [:])
                    let result = invocation.invoke(string: jsonString)

                    expect(mock.hideUserExplorerRef.invokations().count) == 1

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
            }
        }
    }
}
