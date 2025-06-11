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
        if let value = value {
            self.value = NSNumber(value: value)
        } else {
            self.value = nil
        }
        self.properties = properties
        self.internalProperties = internalProperties
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
