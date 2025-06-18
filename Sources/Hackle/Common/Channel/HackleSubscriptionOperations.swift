//
//  HackleSubscriptionOperations.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/16/25.
//
import Foundation

@objc public class HackleSubscriptionOperations: NSObject {
    private let operations: [String: HackleSubscriptionStatus]
    
    var count: Int {
        return operations.count
    }
    
    init(operations: [String: HackleSubscriptionStatus]) {
        self.operations = operations
    }
    
    func toEvent(key: String) -> Event {
        let eventBuilder = HackleEventBuilder(key: key)
        for (operationKey, status) in operations {
            eventBuilder.property(operationKey, status.rawValue)
        }
        return eventBuilder.build()
    }

    @objc public static func builder() -> HackleSubscriptionOperationsBuilder {
        HackleSubscriptionOperationsBuilder()
    }
}

@objc public class HackleSubscriptionOperationsBuilder: NSObject {
    private var operations = [String: HackleSubscriptionStatus]()
    
    @discardableResult
    func set(_ key: String, status: HackleSubscriptionStatus) -> HackleSubscriptionOperationsBuilder {
        self.operations[key] = status
        return self
    }
    
    @discardableResult
    @objc public func global(_ status: HackleSubscriptionStatus) -> HackleSubscriptionOperationsBuilder {
        return self.set("$global", status: status)
    }
    
    @discardableResult
    @objc public func information(_ status: HackleSubscriptionStatus) -> HackleSubscriptionOperationsBuilder {
        return self.set("$information", status: status)
    }
    
    @discardableResult
    @objc public func marketing(_ status: HackleSubscriptionStatus) -> HackleSubscriptionOperationsBuilder {
        return self.set("$marketing", status: status)
    }
    
    @discardableResult
    @objc public func custom(_ key: String, status: HackleSubscriptionStatus) -> HackleSubscriptionOperationsBuilder {
        return self.set(key, status: status)
    }

    @objc public func build() -> HackleSubscriptionOperations {
        return HackleSubscriptionOperations(operations: self.operations)
    }
}
