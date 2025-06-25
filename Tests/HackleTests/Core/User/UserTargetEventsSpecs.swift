//
//  UserTargetEventsSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//

import Foundation
import Nimble
import Quick
@testable import Hackle

class UserTargetEventsSpecs: QuickSpec {
    override func spec() {
        var decoder: JSONDecoder!

        beforeEach {
            decoder = JSONDecoder()
        }
        
        it("UserTargetEvents") {
            expect(UserTargetEvents.empty().count) == 0

            let userTargetEvents = UserTargetEvents.builder()
                .put(targetEvent: TargetEvent(
                    eventKey: "purchase",
                    stats: [
                        TargetEvent.Stat(
                            date: 1737361789000,
                            count: 10)
                    ],
                    property: TargetEvent.Property(
                        key: "product_name",
                        type: .eventProperty,
                        value: HackleValue.string("shampo")
                    )
                ))
                .putAll(targetEvents: UserTargetEvents.builder()
                    .put(targetEvent: TargetEvent(
                        eventKey: "login",
                        stats: [
                            TargetEvent.Stat(
                                date: 1737361789000,
                                count: 5)
                        ],
                        property: TargetEvent.Property(
                            key: "grade",
                            type: .eventProperty,
                            value: HackleValue.string("platinum")
                        )
                    ))
                    .build()
                )
                .build()

            // raw
            expect(userTargetEvents.count) === 2


            // toBuilder
            let singleTargetEvent = userTargetEvents.toBuilder()
                .put(targetEvent: TargetEvent(
                    eventKey: "add_cart",
                    stats: [
                        TargetEvent.Stat(
                            date: 1737361789000,
                            count: 1)
                    ],
                    property: TargetEvent.Property(
                        key: "product_name",
                        type: .eventProperty,
                        value: HackleValue.string("milk")
                    )
                ))
                .build()
            expect(singleTargetEvent.count) == 3
        }
        
        describe("from") {
            it("success") {
                let json = """
                {
                    "events": [
                        {
                            "eventKey": "purchase",
                            "stats": [
                                { "date": 1737361789000, "count": 10 },
                            ],
                        },
                        {
                            "eventKey": "login",
                            "stats": [
                                { "date": 1737361789000, "count": 5 },
                            ]
                        }
                    ]
                }
                """
                let data = json.data(using: .utf8)!
                let response = try! decoder.decode(UserTargetResponseDto.self, from: data)
                let userTargetEvents = UserTargetEvents.from(dto: response)
                expect(userTargetEvents.count) == 2
                expect(userTargetEvents[0].eventKey) == "purchase"
                expect(userTargetEvents[0].stats[0].date) == 1737361789000
                expect(userTargetEvents[0].stats[0].count) == 10
                expect(userTargetEvents[1].eventKey) == "login"
                expect(userTargetEvents[1].stats[0].date) == 1737361789000
                expect(userTargetEvents[1].stats[0].count) == 5
            }
            
            it("success with property") {
                let json = """
                {
                    "events": [
                        {
                            "eventKey": "purchase",
                            "stats": [
                                { "date": 1737361789000, "count": 10 },
                                { "date": 1737361799000, "count": 12 }
                            ],
                            "property": {
                                "key": "amount",
                                "type": "EVENT_PROPERTY",
                                "value": 100.5
                            }
                        },
                        {
                            "eventKey": "login",
                            "stats": [
                                { "date": 1737361789000, "count": 5 },
                                { "date": 1737361799000, "count": 12 }
                            ],
                            "property": {
                                "key": "grade",
                                "type": "EVENT_PROPERTY",
                                "value": "platinum"
                            }
                        }
                    ]
                }
                """
                let data = json.data(using: .utf8)!
                let response = try! decoder.decode(UserTargetResponseDto.self, from: data)
                let userTargetEvents = UserTargetEvents.from(dto: response)
                expect(userTargetEvents.count) == 2
                expect(userTargetEvents[0].eventKey) == "purchase"
                expect(userTargetEvents[0].stats[0].date) == 1737361789000
                expect(userTargetEvents[0].stats[0].count) == 10
                expect(userTargetEvents[0].property?.key) == "amount"
                expect(userTargetEvents[0].property?.type) == .eventProperty
                expect(userTargetEvents[0].property?.value.asDouble()) == 100.5
                
                expect(userTargetEvents[1].eventKey) == "login"
                expect(userTargetEvents[1].stats[0].date) == 1737361789000
                expect(userTargetEvents[1].stats[0].count) == 5
                expect(userTargetEvents[1].property?.key) == "grade"
                expect(userTargetEvents[1].property?.type) == .eventProperty
                expect(userTargetEvents[1].property?.value.asString()) == "platinum"
            }
            
            it("fail parse property") {
                let json = """
                {
                    "events": [
                        {
                            "eventKey": "purchase",
                            "stats": [
                                { "date": 1737361789000, "count": 10 },
                                { "date": 1737361799000, "count": 12 }
                            ],
                            "property": {
                                "key": "amount",
                                "type": "UNKNOWN_PROPERTY",
                                "value": 100.5
                            }
                        }
                    ]
                }
                """
                let data = json.data(using: .utf8)!
                let response = try! decoder.decode(UserTargetResponseDto.self, from: data)
                let userTargetEvents = UserTargetEvents.from(dto: response)
                expect(userTargetEvents.count) == 0
            }
        }
    }
}
