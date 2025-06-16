//
//  DefaultUserDtoSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/16/25.
//

import Foundation
import Nimble
import Quick
@testable import Hackle

class DefaultUserDtoSpecs: QuickSpec {
    override func spec() {
        var decoder: JSONDecoder!

        beforeEach {
            decoder = JSONDecoder()
        }
        
        describe("UserCohortsResponseDto") {
            context("when decoding from valid JSON") {
                it("should decode successfully and map all properties") {
                    // given
                    let json = """
                    {
                        "cohorts": [
                            {
                                "identifier": { "type": "id", "value": "user123" },
                                "cohorts": [101, 102, 103]
                            },
                            {
                                "identifier": { "type": "$id", "value": "device456" },
                                "cohorts": [201]
                            }
                        ]
                    }
                    """
                    let data = json.data(using: .utf8)!

                    // when
                    let response = try? decoder.decode(UserCohortsResponseDto.self, from: data)

                    // then
                    expect(response).toNot(beNil())
                    expect(response?.cohorts.count).to(equal(2))

                    let firstUserCohort = response?.cohorts[0]
                    expect(firstUserCohort?.identifier.type).to(equal("id"))
                    expect(firstUserCohort?.identifier.value).to(equal("user123"))
                    expect(firstUserCohort?.cohorts).to(equal([101, 102, 103]))

                    let secondUserCohort = response?.cohorts[1]
                    expect(secondUserCohort?.identifier.type).to(equal("$id"))
                    expect(secondUserCohort?.identifier.value).to(equal("device456"))
                    expect(secondUserCohort?.cohorts).to(equal([201]))
                }
            }
        }
        
        describe("UserTargetResponseDto") {
            context("when decoding from JSON with all properties in TargetEventDto") {
                it("should decode successfully and map all properties") {
                    // given
                    let json = """
                    {
                        "events": [
                            {
                                "eventKey": "buy",
                                "stats": [
                                    { "date": 20250616, "count": 5 },
                                    { "date": 20250615, "count": 10 }
                                ],
                                "property": {
                                    "key": "amount",
                                    "type": "EVENT_PROPERTY",
                                    "value": 100.5
                                }
                            }
                        ]
                    }
                    """
                    let data = json.data(using: .utf8)!

                    // when
                    let response = try? decoder.decode(UserTargetResponseDto.self, from: data)
                    
                    // then
                    expect(response).toNot(beNil())
                    expect(response?.events.count).to(equal(1))

                    let event = response?.events[0]
                    expect(event?.eventKey).to(equal("buy"))
                    
                    expect(event?.stats.count).to(equal(2))
                    expect(event?.stats[0].date).to(equal(20250616))
                    expect(event?.stats[0].count).to(equal(5))
                    expect(event?.stats[1].date).to(equal(20250615))
                    expect(event?.stats[1].count).to(equal(10))

                    expect(event?.property).toNot(beNil())
                    expect(event?.property?.key).to(equal("amount"))
                    expect(event?.property?.type).to(equal(.eventProperty))
                    expect(event?.property?.value).to(equal(HackleValue.double(100.5)))
                }
            }

            context("TargetEventDto is missing the optional 'property'") {
                it("When property is nil and decoding is successful") {
                    // given
                    let json = """
                    {
                        "events": [
                            {
                                "eventKey": "login",
                                "stats": [
                                    { "date": 20250616, "count": 1 }
                                ]
                            }
                        ]
                    }
                    """
                    let data = json.data(using: .utf8)!

                    // when
                    let response = try? decoder.decode(UserTargetResponseDto.self, from: data)

                    // then
                    expect(response).toNot(beNil())
                    expect(response?.events.count).to(equal(1))

                    let event = response?.events[0]
                    expect(event?.eventKey).to(equal("login"))
                    expect(event?.property).to(beNil())
                }
                
                it("When property decoding fails") {
                    // given
                    let json = """
                    {
                        "events": [
                            {
                                "eventKey": "logout",
                                "stats": [
                                    { "date": 20250616, "count": 1 }
                                ],
                                "property": {
                                    "key": "duration",
                                    "type": "UNSUPPORTED_TYPE",
                                    "value": 30
                                }
                            }
                        ]
                    }
                    """
                    let data = json.data(using: .utf8)!

                    // when
                    let response = try? decoder.decode(UserTargetResponseDto.self, from: data)
                    
                    // then
                    expect(response).toNot(beNil())
                    expect(response?.events.count).to(equal(1))

                    let event = response?.events[0]
                    expect(event?.eventKey).to(equal("logout"))
                    expect(event?.property).to(beNil())
                }
            }
        }
        
        describe("PropertyDto") {
            context("when decoding with an unsupported type") {
                it("should throw a HackleError") {
                    // given
                    let json = """
                    {
                        "key": "some_key",
                        "type": "UNSUPPORTED_TYPE",
                        "value": "some_value"
                    }
                    """
                    let data = json.data(using: .utf8)!

                    // when & then
                    expect { try decoder.decode(PropertyDto.self, from: data) }.to(throwError(HackleError.error("")))
                }
            }

            context("when a required field is missing") {
                it("should throw a HackleError") {
                    // given
                    let json = """
                    {
                        "type": "EVENT_PROPERTY",
                        "value": "some_value"
                    }
                    """
                    let data = json.data(using: .utf8)!

                    // when & then
                    expect { try decoder.decode(PropertyDto.self, from: data) }.to(throwError(HackleError.error("")))
                }
            }
        }
    }
}
