//
// Created by yong on 2020/12/11.
//

import Foundation


@objc(HackleEvent)
public class Event: NSObject, HackleCommonEvent {

    public private(set) var key: String
    public private(set) var value: NSNumber?
    public private(set) var properties: [String: Any]?
    public private(set) var internalProperties: [String: Any]?

    init(key: String, value: Double? = nil, properties: [String: Any]? = nil) {
        self.key = key
        self.value = value as NSNumber?
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
