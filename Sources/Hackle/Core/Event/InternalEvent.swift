//
//  InternalEvent.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/10/25.
//

import Foundation

class InternalEvent: HackleCommonEvent {
    var key: String
    var value: NSNumber?
    var properties: [String : Any]?
    var internalProperties: [String: Any]?

    init(key: String, value: Double? = nil, properties: [String: Any]? = nil, internalProperties: [String: Any]? = nil) {
        self.key = key
        self.value = value as NSNumber?
        self.properties = properties
        self.internalProperties = nil
    }
    
    static func builder(_ key: String) -> HackleInternalEventBuilder {
        HackleInternalEventBuilder(key: key)
    }
}

class HackleInternalEventBuilder: HackleCommonEventBuilder {
    override init(key: String) {
        super.init(key: key)
        self.internalProperties = PropertiesBuilder()
    }
    
    @discardableResult
    func internalProperty(_ key: String, _ value: Any) -> Self {
        internalProperties?.add(key, value)
        return self
    }
    
    func build() -> InternalEvent {
        InternalEvent(key: key, value: value, properties: properties.build(), internalProperties: internalProperties?.build())
    }
}
