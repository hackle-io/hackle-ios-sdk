import Foundation
@testable import Hackle
import MockingKit
import Nimble
import Quick

class HackleInvocationSpec: QuickSpec {
    func createJsonString(command: String, parameters: [String: Any?]? = nil) -> String {
        return [
            "_hackle": [
                "command": command,
                "parameters": parameters ?? nil,
                "browserProperties": [
                    "mock": "mocks"
                ]
            ] as [String: Any?]
        ].toJson() ?? ""
    }
    
    override func spec() {
        var core: MockHackleAppCore!
        var processor: InvocationProcessor!
        var sut: DefaultHackleInvocator!
        
        beforeEach {
            core = MockHackleAppCore()
            processor = DefaultInvocationProcessor(handlerFactory: DefaultInvocationHandlerFactory(core: core))
            sut = DefaultHackleInvocator(processor: processor)
        }
        
        it("is invocable string") {
            expect(sut.isInvocableString(string: "{\"_hackle\":{\"command\":\"foo\"}}")) == true
            expect(sut.isInvocableString(string: "{\"_hackle\":{\"command\":\"\"}}")) == false
            expect(sut.isInvocableString(string: "{\"_hackle\":\"\"}}")) == false
            expect(sut.isInvocableString(string: "{\"_hackle\":{}}}")) == false
            expect(sut.isInvocableString(string: "{\"something\":{\"command\":\"\"}}")) == false
            expect(sut.isInvocableString(string: "{")) == false
            expect(sut.isInvocableString(string: "")) == false
        }
        describe("invoke") {
            it("get session id") {
                let sessionId = "1234567890.abcdefgh"
                core.sessionId = sessionId
                
                let jsonString = self.createJsonString(command: "getSessionId")
                let result = sut.invoke(string: jsonString)
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
                core.user = user
                
                let jsonString = self.createJsonString(command: "getUser")
                let result = sut.invoke(string: jsonString)
                
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
                            ] as [String: Any?]
                        ] as [String: Any]
                    ]

                    let jsonString = self.createJsonString(command: "setUser", parameters: parameters)
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.setUserRef.invokations().count) == 1
                    let firstInvokation = core.setUserRef.firstInvokation()
                    let arguments = firstInvokation.arguments.0
                    expect(arguments.id) == "foo"
                    expect(arguments.userId) == "bar"
                    expect(arguments.identifiers).to(equal(["foobar": "foofoo", "foobar2": "barbar"]))
                    expect(arguments.properties["number"] as? Double) == 123.0
                    expect(arguments.properties["string"] as? String) == "text"
                    
                    let array = arguments.properties["array"] as! [Any]
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
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.setUserRef.invokations().count) == 0
                    
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
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.setUserIdRef.invokations().count) == 1
                    let tempInvocation = core.setUserIdRef.firstInvokation()
                    expect(tempInvocation.arguments.0) == "abcd1234"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "setUserId", parameters: [:])
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.setUserIdRef.invokations().count) == 0
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                    expect(dict["message"]).toNot(beNil())
                    expect(dict["data"]).to(beNil())
                }
                it("nil case") {
                    let jsonString = self.createJsonString(command: "setUserId", parameters: ["userId": nil])
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.setUserIdRef.invokations().count) == 1
                    
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
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.setDeviceIdRef.invokations().count) == 1
                    let tempInvocation = core.setDeviceIdRef.firstInvokation()
                    expect(tempInvocation.arguments.0) == "abcd1234"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "setDeviceId", parameters: [:])
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.setDeviceIdRef.invokations().count) == 0
                    
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
                        "value": "bar"
                    ]
                    let jsonString = self.createJsonString(command: "setUserProperty", parameters: parameters)
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.updateUserPropertiesRef.invokations().count) == 1
                    let firstInvokation = core.updateUserPropertiesRef.firstInvokation()
                    let arguments = firstInvokation.arguments.0.asDictionary()
                    let set = arguments[PropertyOperation.set]!
                    expect(set.count) == 1
                    expect(set["foo"] as? String) == "bar"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "setUserProperty", parameters: [:])
                    let result = sut.invoke(string: jsonString)

                    expect(core.updateUserPropertiesRef.invokations().count) == 0

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
                            ] as [String: Any?],
                            "$setOnce": [
                                "foo": "bar"
                            ]
                        ]
                    ]
                    let jsonString = self.createJsonString(command: "updateUserProperties", parameters: parameters)
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.updateUserPropertiesRef.invokations().count) == 1
                    let firstInvokation = core.updateUserPropertiesRef.firstInvokation()
                    let arguments = firstInvokation.arguments.0.asDictionary()
                    
                    let set = arguments[PropertyOperation.set]!
                    expect(set.count) == 3
                    expect(set["number"] as? Double) == 123.0
                    expect(set["string"] as? String) == "text"
                    
                    let array = set["array"] as! [Any]
                    expect(array.count) == 2
                    expect(array[0] as? Double) == 123.0
                    expect(array[1] as? String) == "123"
                    
                    let setOnce = arguments[PropertyOperation.setOnce]!
                    expect(setOnce["foo"] as? String) == "bar"
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "updateUserProperties", parameters: [:])
                    let result = sut.invoke(string: jsonString)

                    expect(core.updateUserPropertiesRef.invokations().count) == 0

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
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.updatePushSubscriptionsRef.invokations().count) == 1
                    
                    let firstInvokation = core.updatePushSubscriptionsRef.firstInvokation()
                    let arguments = firstInvokation.arguments
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
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                
                it("sms") {
                    let jsonString = self.createJsonString(command: "updateSmsSubscriptions", parameters: parameters)
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.updateSmsSubscriptionsRef.invokations().count) == 1
                    
                    let firstInvokation = core.updateSmsSubscriptionsRef.firstInvokation()
                    let arguments = firstInvokation.arguments
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
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                
                it("kakao") {
                    let jsonString = self.createJsonString(command: "updateKakaoSubscriptions", parameters: parameters)
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.updateKakaoSubscriptionsRef.invokations().count) == 1
                    
                    let firstInvokation = core.updateKakaoSubscriptionsRef.firstInvokation()
                    let arguments = firstInvokation.arguments
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
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
            }
            it("reset user") {
                let jsonString = self.createJsonString(command: "resetUser", parameters: [:])
                let result = sut.invoke(string: jsonString)
                
                expect(core.resetUserRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
                expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
            }
            it("setPhoneNumber") {
                let jsonString = self.createJsonString(command: "setPhoneNumber", parameters: ["phoneNumber": "+821012345678"])
                let result = sut.invoke(string: jsonString)
                
                expect(core.setPhoneNumberRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
                expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
            }
            it("unsetPhoneNumber") {
                let jsonString = self.createJsonString(command: "unsetPhoneNumber")
                let result = sut.invoke(string: jsonString)
                
                expect(core.unsetPhoneNumberRef.invokations().count) == 1
                
                let dict = result.jsonObject()!
                expect(dict["success"] as? Bool) == true
                expect(dict["message"] as? String) == "OK"
                expect(dict["data"]).to(beNil())
                expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
            }
            describe("variation") {
                context("normal") {
                    it("happy case") {
                        let parameters = [
                            "experimentKey": 123,
                            "defaultVariation": "D"
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0) == 123
                        expect(arguments.1).to(beNil())
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = ["experimentKey": 123] as [String: Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "abcd1234"
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": "abcd1234"
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0) == 123
                        expect(arguments.1?.id) == "foo"
                        expect(arguments.2) == "D"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? String) == "C"
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": ["id": "foo"]
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variation", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                    let result = sut.invoke(string: jsonString)

                    expect(core.variationDetailRef.invokations().count) == 0

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
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": "abcd1234"
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "C", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("expect 'A' default variation parameter") {
                        let parameters = [
                            "experimentKey": 123,
                            "user": ["id": "foo"]
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "variationDetail", parameters: parameters)
                        every(core.variationDetailRef)
                            .returns(Decision.of(experiment: nil, variation: "A", reason: "DEFAULT_RULE"))
                        
                        let result = sut.invoke(string: jsonString)
                        expect(core.variationDetailRef.invokations().count) == 1
                        
                        let firstInvokation = core.variationDetailRef.firstInvokation()
                        let arguments = firstInvokation.arguments
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
                    let result = sut.invoke(string: jsonString)

                    expect(core.variationDetailRef.invokations().count) == 0

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
                    ] as [String: Any]
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(core.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = sut.invoke(string: jsonString)
                    expect(core.featureFlagDetailRef.invokations().count) == 1
                        
                    let firstInvokation = core.featureFlagDetailRef.firstInvokation()
                    let arguments = firstInvokation.arguments
                    expect(arguments.0) == 123
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("with user string case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": "abcd1234"
                    ] as [String: Any]
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(core.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = sut.invoke(string: jsonString)
                    expect(core.featureFlagDetailRef.invokations().count) == 1
                        
                    let firstInvokation = core.featureFlagDetailRef.firstInvokation()
                    let arguments = firstInvokation.arguments
                    expect(arguments.0) == 123
                    expect(arguments.1?.id) == "abcd1234"
                        
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("with user object case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": ["id": "foo"]
                    ] as [String: Any]
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: parameters)
                    every(core.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = sut.invoke(string: jsonString)
                    expect(core.featureFlagDetailRef.invokations().count) == 1
                        
                    let firstInvokation = core.featureFlagDetailRef.firstInvokation()
                    let arguments = firstInvokation.arguments
                    expect(arguments.0) == 123
                    expect(arguments.1?.id) == "foo"

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"] as? Bool) == true
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "isFeatureOn", parameters: [:])
                    let result = sut.invoke(string: jsonString)

                    expect(core.featureFlagDetailRef.invokations().count) == 0

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
                    ] as [String: Any]
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(core.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = sut.invoke(string: jsonString)
                    expect(core.featureFlagDetailRef.invokations().count) == 1
                        
                    let firstInvokation = core.featureFlagDetailRef.firstInvokation()
                    let arguments = firstInvokation.arguments
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
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("with user string case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": "abcd1234"
                    ] as [String: Any]
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(core.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = sut.invoke(string: jsonString)
                    expect(core.featureFlagDetailRef.invokations().count) == 1
                        
                    let firstInvokation = core.featureFlagDetailRef.firstInvokation()
                    let arguments = firstInvokation.arguments
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
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("with user case") {
                    let parameters = [
                        "featureKey": 123,
                        "user": ["id": "foo"]
                    ] as [String: Any]
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: parameters)
                    every(core.featureFlagDetailRef)
                        .returns(FeatureFlagDecision.on(featureFlag: nil, reason: "DEFAULT_RULE"))
                        
                    let result = sut.invoke(string: jsonString)
                    expect(core.featureFlagDetailRef.invokations().count) == 1
                        
                    let firstInvokation = core.featureFlagDetailRef.firstInvokation()
                    let arguments = firstInvokation.arguments
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
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "featureFlagDetail", parameters: [:])
                    let result = sut.invoke(string: jsonString)

                    expect(core.featureFlagDetailRef.invokations().count) == 0

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
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.trackRef.invokations().count) == 1
                        
                        let firstInvokation = core.trackRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0.key) == "abcd1234"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("with user string") {
                        let parameters = [
                            "event": "abcd1234",
                            "user": "foo"
                        ]
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.trackRef.invokations().count) == 1
                        
                        let firstInvokation = core.trackRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0.key) == "abcd1234"
                        expect(arguments.1?.id) == "foo"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("with user object") {
                        let parameters = [
                            "event": "abcd1234",
                            "user": ["id": "foo"]
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.trackRef.invokations().count) == 1
                        
                        let firstInvokation = core.trackRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0.key) == "abcd1234"
                        expect(arguments.1?.id) == "foo"
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
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
                                ] as [String: Any?]
                            ] as [String: Any]
                        ]
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.trackRef.invokations().count) == 1
                        
                        let firstInvokation = core.trackRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0.key) == "foo"
                        expect(arguments.0.value) == 1234
                        expect(arguments.0.properties!.count) == 3
                        expect(arguments.0.properties!["number"] as? Double) == 123.0
                        expect(arguments.0.properties!["string"] as? String) == "text"
                        
                        let array = arguments.0.properties!["array"] as! [Any]
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.0.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
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
                                ] as [String: Any?]
                            ] as [String: Any],
                            "user": "abcd1234"
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.trackRef.invokations().count) == 1
                        
                        let firstInvokation = core.trackRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0.key) == "foo"
                        expect(arguments.0.value) == 1234
                        expect(arguments.0.properties!.count) == 3
                        expect(arguments.0.properties!["number"] as? Double) == 123.0
                        expect(arguments.0.properties!["string"] as? String) == "text"
                        expect(arguments.1?.id) == "abcd1234"
                        
                        let array = arguments.0.properties!["array"] as! [Any]
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.0.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
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
                                ] as [String: Any?]
                            ] as [String: Any],
                            "user": ["id": "abcd1234"]
                        ] as [String: Any]
                        let jsonString = self.createJsonString(command: "track", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.trackRef.invokations().count) == 1
                        
                        let firstInvokation = core.trackRef.firstInvokation()
                        let arguments = firstInvokation.arguments
                        expect(arguments.0.key) == "foo"
                        expect(arguments.0.value) == 1234
                        expect(arguments.0.properties!.count) == 3
                        expect(arguments.0.properties!["number"] as? Double) == 123.0
                        expect(arguments.0.properties!["string"] as? String) == "text"
                        expect(arguments.1?.id) == "abcd1234"

                        let array = arguments.0.properties!["array"] as! [Any]
                        expect(array.count) == 2
                        expect(array[0] as? Double) == 123.0
                        expect(array[1] as? String) == "123"
                        expect(arguments.0.properties!["map"]).to(beNil())
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"]).to(beNil())
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                }
                it("invalid parameters case") {
                    let jsonString = self.createJsonString(command: "track", parameters: [:])
                    let result = sut.invoke(string: jsonString)

                    expect(core.trackRef.invokations().count) == 0

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
                        ] as [String: Any]
                        
                        every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234.5678), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.remoteConfigRef.invokations().count) == 1
                        
                        let dict = result.jsonObject()!
                        expect(dict["success"] as? Bool) == true
                        expect(dict["message"] as? String) == "OK"
                        expect(dict["data"] as? Double) == 1234.5678
                        expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                    }
                    it("number default value return case") {
                        let parameters = [
                            "key": "number",
                            "valueType": "number",
                            "defaultValue": 0
                        ] as [String: Any]
                        every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "notnumber"), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.remoteConfigRef.invokations().count) == 1
                        
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
                        ] as [String: Any]
                        every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.remoteConfigRef.invokations().count) == 1
                        
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
                        ] as [String: Any]
                        every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.remoteConfigRef.invokations().count) == 1
                        
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
                        ] as [String: Any]
                        every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "abcd1234"), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.remoteConfigRef.invokations().count) == 1
                        
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
                        ] as [String: Any]
                        every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234), reason: ""))
                        
                        let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                        let result = sut.invoke(string: jsonString)
                        
                        expect(core.remoteConfigRef.invokations().count) == 1
                        
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
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234.5678), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
                            expect(arguments.2?.id) == "abcd1234"
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
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "notnumber"), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                                "user": "abcd1234"
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                                "user": "abcd1234"
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                                "user": "abcd1234"
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "abcd1234"), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                                "user": "abcd1234"
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
                            expect(arguments.2?.id) == "abcd1234"

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
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234.5678), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
                            expect(arguments.2?.id) == "abcd1234"

                            let dict = result.jsonObject()!
                            expect(dict["success"] as? Bool) == true
                            expect(dict["message"] as? String) == "OK"
                            expect(dict["data"] as? Double) == 1234.5678
                            expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                        }
                        it("number default value return case") {
                            let parameters = [
                                "key": "number",
                                "valueType": "number",
                                "defaultValue": 0,
                                "user": ["id": "abcd1234"]
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: "abcd1234"), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                            ] as [String: Any]
                            every(core.remoteConfigRef).returns(RemoteConfigDecision(value: HackleValue(value: 1234), reason: ""))
                            let jsonString = self.createJsonString(command: "remoteConfig", parameters: parameters)
                            let result = sut.invoke(string: jsonString)
                            expect(core.remoteConfigRef.invokations().count) == 1
                            let firstInvokation = core.remoteConfigRef.firstInvokation()
                            let arguments = firstInvokation.arguments
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
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.remoteConfigRef.invokations().count) == 0
                    
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
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.setCurrentScreenRef.invokations().count) == 1
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                    expect(core.hackleAppContext?.browserProperties["mock"] as? String) == "mocks"
                }
            }
            describe("setOptOutTracking") {
                it("optOut=true이면 setOptOutTracking(true) 호출") {
                    let jsonString = self.createJsonString(command: "setOptOutTracking", parameters: ["optOut": true])
                    let result = sut.invoke(string: jsonString)

                    expect(core.setOptOutTrackingRef.invokations().count) == 1
                    expect(core.setOptOutTrackingRef.invokations().first?.arguments) == true

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }

                it("optOut=false이면 setOptOutTracking(false) 호출") {
                    let jsonString = self.createJsonString(command: "setOptOutTracking", parameters: ["optOut": false])
                    let result = sut.invoke(string: jsonString)

                    expect(core.setOptOutTrackingRef.invokations().count) == 1
                    expect(core.setOptOutTrackingRef.invokations().first?.arguments) == false

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }

                it("optOut 파라미터 누락 시 에러 응답") {
                    let jsonString = self.createJsonString(command: "setOptOutTracking", parameters: [:])
                    let result = sut.invoke(string: jsonString)

                    expect(core.setOptOutTrackingRef.invokations().count) == 0

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == false
                }
            }
            describe("user explorer") {
                it("show") {
                    let jsonString = self.createJsonString(command: "showUserExplorer", parameters: [:])
                    let result = sut.invoke(string: jsonString)
                    
                    expect(core.showUserExplorerRef.invokations().count) == 1
                    
                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
                
                it("hide") {
                    let jsonString = self.createJsonString(command: "hideUserExplorer", parameters: [:])
                    let result = sut.invoke(string: jsonString)

                    expect(core.hideUserExplorerRef.invokations().count) == 1

                    let dict = result.jsonObject()!
                    expect(dict["success"] as? Bool) == true
                    expect(dict["message"] as? String) == "OK"
                    expect(dict["data"]).to(beNil())
                }
            }
        }
    }
}
