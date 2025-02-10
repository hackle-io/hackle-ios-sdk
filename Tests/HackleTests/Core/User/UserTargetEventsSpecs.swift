//
//  UserTargetEventsSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//

import Nimble
import Quick
@testable import Hackle


// please unit test usertargetevent

class UserTargetEventsSpecs: QuickSpec {
    override func spec() {
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
    }
}
