//
//  HacklePushSubscriptionOperations.swift
//  Hackle
//
//  Created by hackle on 9/19/24.
//

import Foundation

@available(*, deprecated, message: "Use HackleSubscriptionStatus instead.")
enum HacklePushSubscriptionType: String {
    case global = "$global"
}

@available(*, deprecated, message: "Use HackleSubscriptionOperations instead.")
@objc public class HacklePushSubscriptionOperations: NSObject {
    private let operations: [String: HacklePushSubscriptionStatus]
    
    var count: Int {
        return operations.count
    }
    
    init(operations: [String: HacklePushSubscriptionStatus]) {
        self.operations = operations
    }
    
    func toEvent() -> Event {
        let builder = Event.builder("$push_subscriptions")
        for (key, value) in operations {
            builder.property(key, value.rawValue)
        }
        return builder.build()
    }
    
    @objc public static func builder() -> HacklePushSubscriptionOperationsBuilder {
        HacklePushSubscriptionOperationsBuilder()
    }
}

@available(*, deprecated, message: "Use HackleSubscriptionOperationsBuilder instead.")
@objc public class HacklePushSubscriptionOperationsBuilder: NSObject {
    private var operations = [String: HacklePushSubscriptionStatus]()
    
    @objc public func global(_ status: HacklePushSubscriptionStatus) -> HacklePushSubscriptionOperationsBuilder {
        self.operations[HacklePushSubscriptionType.global.rawValue] = status
        return self
    }
    
    @objc public func build() -> HacklePushSubscriptionOperations {
        return HacklePushSubscriptionOperations(operations: self.operations)
    }
}
