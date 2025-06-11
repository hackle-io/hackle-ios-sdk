//
//  HackleCommonEvent.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/11/25.
//
import Foundation

public protocol HackleCommonEvent {
    var key: String { get }
    var value: NSNumber? { get }
    var properties: [String: Any]? { get }
    var internalProperties: [String: Any]? { get }
}

public class HackleCommonEventBuilder: NSObject {
    let key: String
    var value: Double? = nil
    var properties: PropertiesBuilder = PropertiesBuilder()
    var internalProperties: PropertiesBuilder? = nil

    init(key: String) {
        self.key = key
    }

    @discardableResult
    public func value(_ value: Double) -> Self {
        self.value = value
        return self
    }

    @discardableResult
    public func property(_ key: String, _ value: Any?) -> Self {
        self.properties.add(key, value)
        return self
    }

    @discardableResult
    public func properties(_ properties: [String: Any]) -> Self {
        self.properties.add(properties)
        return self
    }
}
