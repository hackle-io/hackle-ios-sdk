//
// Created by yong on 2020/12/11.
//

import Foundation

@objc(HackleEvent)
public class Event: NSObject, HackleCommonEvent {

    public let key: String
    public let value: NSNumber?
    public let properties: [String: Any]?
    public let internalProperties: [String: Any]?

    init(key: String, value: Double? = nil, properties: [String: Any]? = nil) {
        self.key = key
        if let value = value {
            self.value = NSNumber(value: value)
        } else {
            self.value = nil
        }
        self.properties = properties
        self.internalProperties = nil
    }

    @objc public static func builder(_ key: String) -> HackleEventBuilder {
        HackleEventBuilder(key: key)
    }
}

@objc public class HackleEventBuilder: HackleCommonEventBuilder {
    @objc public func build() -> Event {
        Event(key: key, value: value, properties: properties.build())
    }
}
