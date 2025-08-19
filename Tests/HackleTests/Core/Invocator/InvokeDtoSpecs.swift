//
//  InvokeDtoSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/13/25.
//

import Quick
import Nimble
import Foundation
@testable import Hackle

// MARK: - Test Spec

class InvokeDtoSpecs: QuickSpec {
    override func spec() {

        // MARK: - User
        describe("User extension") {

            context("when converting from User to Dto") {
                it("should create a Dto with all properties") {
                    // given
                    let user = User.builder()
                        .id("hackle_id")
                        .userId("test_user")
                        .deviceId("test_device")
                        .identifiers(["customId": "custom_value"])
                        .properties(["age": 30, "isVip": true])
                        .build()

                    // when
                    let dto = user.toDto()

                    // then
                    expect(dto["id"] as? String).to(equal("hackle_id"))
                    expect(dto["userId"] as? String).to(equal("test_user"))
                    expect(dto["deviceId"] as? String).to(equal("test_device"))
                    expect(dto["identifiers"] as? [String: String]).to(equal(["customId": "custom_value"]))
                    let properties = dto["properties"] as? [String: Any]
                    expect(properties?["age"] as? Int).to(equal(30))
                    expect(properties?["isVip"] as? Bool).to(beTrue())
                }

                it("should not include nil values in the Dto") {
                    // given
                    let user = User.builder().userId("test_user").build()

                    // when
                    let dto = user.toDto()

                    // then
                    expect(dto["userId"] as? String).to(equal("test_user"))
                    expect(dto["id"]).to(beNil())
                    expect(dto["deviceId"]).to(beNil())
                    expect((dto["identifiers"] as? [String: String])?.count).to(equal(0))
                    expect((dto["properties"] as? [String: Any])?.count).to(equal(0))
                }
            }

            context("when converting from Dto to User") {
                it("should create a User with all properties from the Dto") {
                    // given
                    let dto: UserDto = [
                        "id": "hackle_id",
                        "userId": "test_user",
                        "deviceId": "test_device",
                        "identifiers": ["customId": "custom_value"],
                        "properties": ["age": 30, "isVip": true as Bool]
                    ]

                    // when
                    let user = User.from(dto: dto)

                    // then
                    expect(user).toNot(beNil())
                    expect(user?.id).to(equal("hackle_id"))
                    expect(user?.userId).to(equal("test_user"))
                    expect(user?.deviceId).to(equal("test_device"))
                    expect(user?.identifiers).to(equal(["customId": "custom_value"]))
                    let properties = user?.properties
                    expect(properties?["age"] as? Int).to(equal(30))
                    expect(properties?["isVip"] as? Bool).to(beTrue())
                }

                it("should create a User even if some properties are missing") {
                    // given
                    let dto: UserDto = ["userId": "test_user"]

                    // when
                    let user = User.from(dto: dto)

                    // then
                    expect(user).toNot(beNil())
                    expect(user?.userId).to(equal("test_user"))
                    expect(user?.id).to(beNil())
                }
            }
        }

        // MARK: - Event
        describe("Event extension") {
            context("when converting from Dto to Event") {
                it("should create an Event with all properties") {
                    // given
                    let dto: EventDto = [
                        "key": "purchase",
                        "value": 9.99,
                        "properties": ["item": "sword", "quantity": 1]
                    ]

                    // when
                    let event = Event.from(dto: dto)

                    // then
                    expect(event).toNot(beNil())
                    expect(event?.key).to(equal("purchase"))
                    expect(event?.value).to(equal(9.99))
                    let properties = event?.properties
                    expect(properties?["item"] as? String).to(equal("sword"))
                    expect(properties?["quantity"] as? Int).to(equal(1))
                }

                it("should return nil if the key is missing") {
                    // given
                    let dto: EventDto = ["value": 100.0]

                    // when
                    let event = Event.from(dto: dto)

                    // then
                    expect(event).to(beNil())
                }
            }
        }

        // MARK: - Decision
        describe("Decision extension") {
            context("when converting from Decision to Dto") {
                it("should create a Dto with variation, reason, and config") {
                    // given
                    let decision = Decision.of(experiment: nil, variation: "A", reason: "TRAFFIC_ALLOCATED")

                    // when
                    let dto = decision.toDto()

                    // then
                    expect(dto["variation"] as? String).to(equal("A"))
                    expect(dto["reason"] as? String).to(equal("TRAFFIC_ALLOCATED"))
                    let config = dto["config"] as? [String: Any]
                    expect(config?["parameters"] as? [String: String]).to(equal([:]))
                }
            }
        }

        // MARK: - FeatureFlagDecision
        describe("FeatureFlagDecision extension") {
            context("when converting from FeatureFlagDecision to Dto") {
                it("should create a Dto with isOn, reason, and config") {
                    // given
                    let decision = FeatureFlagDecision.on(featureFlag: nil, reason: "TARGET_RULE_MATCH")
                    
                    // when
                    let dto = decision.toDto()

                    // then
                    expect(dto["isOn"] as? Bool).to(beTrue())
                    expect(dto["reason"] as? String).to(equal("TARGET_RULE_MATCH"))
                    let config = dto["config"] as? [String: Any]
                    expect(config?["parameters"] as? [String: Int]).to(equal([:]))
                }
            }
        }

        // MARK: - PropertyOperations
        describe("PropertyOperations extension") {
            context("when converting from Dto to PropertyOperations") {
                it("should correctly build operations from the Dto") {
                    // given
                    let dto: PropertyOperationsDto = [
                        "$set": ["name": "hackle"],
                        "$setOnce": ["first_open": true],
                        "$increment": ["login_count": 1],
                        "$unset": ["old_property": 0], // value is ignored
                        "$invalid_op": ["a": "b"]
                    ]

                    // when
                    let operations = PropertyOperations.from(dto: dto)

                    // then
                    let expected = PropertyOperationsBuilder()
                        .set("name", "hackle")
                        .setOnce("first_open", true)
                        .increment("login_count", 1)
                        .unset("old_property")
                        .build()
                    
                    expected.asDictionary().forEach { key, value in
                        let tmp = NSDictionary(dictionary: operations.asDictionary()[key]!)
                        let tmp2 = NSDictionary(dictionary: value )
                        expect(tmp == tmp2).to(equal(true))
                    }
                }
            }
        }
        
        // MARK: - HackleSubscriptionOperations
        describe("HackleSubscriptionOperations extension") {
            context("when converting from Dto to HackleSubscriptionOperations") {
                it("should correctly build subscription operations") {
                    // given
                    let dto: HackleSubscriptionOperationsDto = [
                        "$information": "SUBSCRIBED",
                        "$marketing": "UNSUBSCRIBED",
                        "chat": "UNKNOWN"
                    ]
                    
                    // when
                    let operations = HackleSubscriptionOperations.from(dto: dto)
                    
                    // then
                    let expected = HackleSubscriptionOperations.builder()
                        .information(.subscribed)
                        .marketing(.unsubscribed)
                        .custom("chat", status: .unknown)
                        .build()
                    
                    let operationProperties = operations.toEvent(key: "tmp").properties
                    
                    expected.toEvent(key: "tmp").properties!.forEach { key, value in
                        expect(HackleSubscriptionStatus(rawValue: value as! String) == HackleSubscriptionStatus(rawValue: operationProperties![key] as! String)).to(equal(true))
                    }
                }
                
                it("should return an empty operation if dto is empty") {
                    // given
                    let dto: HackleSubscriptionOperationsDto = [:]
                    
                    // when
                    let operations = HackleSubscriptionOperations.from(dto: dto)
                    
                    // then
                    let expected = HackleSubscriptionOperations.builder().build()
                    expect(operations.toEvent(key: "tmp").properties!.count).to(equal(expected.toEvent(key: "tmp").properties!.count))
                }
            }
        }
    }
}

