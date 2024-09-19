//
//  HacklePushSubsciption.swift
//  Hackle
//
//  Created by hackle on 9/19/24.
//

import Foundation

enum HacklePushSubscriptionOperation: String {
    case global = "$global"
}

@objc public class HacklePushSubscriptionOperations: NSObject {
    private let operations: [HacklePushSubscriptionOperation: String]
    
    var count: Int {
        return operations.count
    }
    
    init(operations: [HacklePushSubscriptionOperation: String]) {
        self.operations = operations
    }
    
    func toEvent() -> Event {
        let builder = Event.builder("$push_subscriptions")
        for (key, value) in operations {
            builder.property(key.rawValue, value)
        }
        return builder.build()
    }
    
    @objc public static func builder() -> HacklePushSubscriptionOperationsBuilder {
        HacklePushSubscriptionOperationsBuilder()
    }
}

@objc public class HacklePushSubscriptionOperationsBuilder: NSObject {
    private var operations = [HacklePushSubscriptionOperation: String]()
    
    @objc public func setGlobal(_ state: HacklePushSubscriptionStateType) -> HacklePushSubscriptionOperationsBuilder {
        self.operations[.global] = state.rawValue
        return self
    }
    
    @objc public func build() -> HacklePushSubscriptionOperations {
        return HacklePushSubscriptionOperations(operations: self.operations)
    }
}
