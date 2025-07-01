//
//  HackleSubscriptionSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/18/25.
//

import Quick
import Nimble
@testable import Hackle

class HackleSubscriptionSpecs: QuickSpec {
    override func spec() {
        describe("HackleSubscriptionStatus") {
            it("should initialize with raw value") {
                expect(HackleSubscriptionStatus(rawValue: "SUBSCRIBED")).to(equal(.subscribed))
                expect(HackleSubscriptionStatus(rawValue: "UNSUBSCRIBED")).to(equal(.unsubscribed))
                expect(HackleSubscriptionStatus(rawValue: "UNKNOWN")).to(equal(.unknown))
                expect(HackleSubscriptionStatus(rawValue: "INVALID")).to(beNil())
            }
            
            it("should return correct raw value") {
                expect(HackleSubscriptionStatus.subscribed.rawValue).to(equal("SUBSCRIBED"))
                expect(HackleSubscriptionStatus.unsubscribed.rawValue).to(equal("UNSUBSCRIBED"))
                expect(HackleSubscriptionStatus.unknown.rawValue).to(equal("UNKNOWN"))
            }
        }
        
        describe("HackleSubscriptionOperations") {
            it("should build subscription operations with correct values") {
                let builder = HackleSubscriptionOperationsBuilder()
                let operations = builder
                    .marketing(.unsubscribed)
                    .information(.unknown)
                    .custom("chat", status: .subscribed)
                    .build()
                
                expect(operations.count) == 3
                let mockEvent = operations.toEvent(key: "mockEvent")
                expect(mockEvent.key) == "mockEvent"
                expect(mockEvent.properties?["$marketing"] as? String).to(equal("UNSUBSCRIBED"))
                expect(mockEvent.properties?["$information"] as? String).to(equal("UNKNOWN"))
                expect(mockEvent.properties?["chat"] as? String).to(equal("SUBSCRIBED"))
            }
        }
    }
}
