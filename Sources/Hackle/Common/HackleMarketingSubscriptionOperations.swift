//
//  HackleMarketingSubscriptionOperations.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/16/25.
//
import Foundation

@objc public class HackleMarketingSubscriptionOperations: NSObject {
    private let operations: [String: HackleMarketingSubscriptionStatus]
    
    var count: Int {
        return operations.count
    }
    
    init(operations: [String: HackleMarketingSubscriptionStatus]) {
        self.operations = operations
    }
    
    func toPushSubscriptionEvent() -> Event {
        let builder = Event.builder("$push_subscriptions")
        for (key, value) in operations {
            builder.property(key, value.rawValue)
        }
        return builder.build()
    }
    
    func toSmsSubscriptionEvent() -> Event {
        let builder = Event.builder("$sms_subscriptions")
        for (key, value) in operations {
            builder.property(key, value.rawValue)
        }
        return builder.build()
    }
    
    func toKakaoSubscriptionEvent() -> Event {
        let builder = Event.builder("$kakao_subscriptions")
        for (key, value) in operations {
            builder.property(key, value.rawValue)
        }
        return builder.build()
    }
    
    @objc public static func builder() -> HackleMarketingSubscriptionOperationsBuilder {
        HackleMarketingSubscriptionOperationsBuilder()
    }
}

@objc public class HackleMarketingSubscriptionOperationsBuilder: NSObject {
    private var operations = [String: HackleMarketingSubscriptionStatus]()
    
    @objc public func global(_ status: HackleMarketingSubscriptionStatus) -> HackleMarketingSubscriptionOperationsBuilder {
        self.operations[HackleMarketingSubscriptionType.global.rawValue] = status
        return self
    }
    
    @objc public func build() -> HackleMarketingSubscriptionOperations {
        return HackleMarketingSubscriptionOperations(operations: self.operations)
    }
}
