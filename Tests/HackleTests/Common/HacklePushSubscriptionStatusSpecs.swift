//
//  HacklePushSubscriptionStatusSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/7/25.
//

import Quick
import Nimble
@testable import Hackle

@available(*, deprecated, message: "")
class HacklePushSubscriptionStatusSpecs: QuickSpec {
    override func spec() {
        describe("HacklePushSubscriptionStatus") {
            it("rawValue로 초기화가 정상 동작한다") {
                expect(HacklePushSubscriptionStatus(rawValue: "SUBSCRIBED")) == .subscribed
                expect(HacklePushSubscriptionStatus(rawValue: "UNSUBSCRIBED")) == .unsubscribed
                expect(HacklePushSubscriptionStatus(rawValue: "UNKNOWN")) == .unknown
                expect(HacklePushSubscriptionStatus(rawValue: "INVALID")).to(beNil())
            }
            
            it("enum에서 rawValue 변환이 정상 동작한다") {
                expect(HacklePushSubscriptionStatus.subscribed.rawValue) == "SUBSCRIBED"
                expect(HacklePushSubscriptionStatus.unsubscribed.rawValue) == "UNSUBSCRIBED"
                expect(HacklePushSubscriptionStatus.unknown.rawValue) == "UNKNOWN"
            }
        }
    }
}
