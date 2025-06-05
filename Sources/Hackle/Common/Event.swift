//
// Created by yong on 2020/12/11.
//

import Foundation

@objc public class Event: NSObject {

    let key: String
    let value: Double?
    let properties: [String: Any]?
    var internalProperties: [String: Any]?

    init(key: String, value: Double? = nil, properties: [String: Any]? = nil) {
        self.key = key
        self.value = value
        self.properties = properties
        self.internalProperties = nil
    }

    @objc public static func builder(_ key: String) -> HackleEventBuilder {
        HackleEventBuilder(key: key)
    }
}

@objc public class HackleEventBuilder: NSObject {

    private let key: String
    private var value: Double? = nil
    private var properties: PropertiesBuilder = PropertiesBuilder()
    private var internalProperties: PropertiesBuilder? = nil

    init(key: String) {
        self.key = key
        super.init()
    }

    @discardableResult
    @objc public func value(_ value: Double) -> HackleEventBuilder {
        self.value = value
        return self
    }

    @discardableResult
    @objc public func property(_ key: String, _ value: Any?) -> HackleEventBuilder {
        self.properties.add(key, value)
        return self
    }

    @discardableResult
    @objc public func properties(_ properties: [String: Any]) -> HackleEventBuilder {
        self.properties.add(properties)
        return self
    }

    @objc public func build() -> Event {
        let event = Event(key: key, value: value, properties: properties.build())
        event.addInternalProperties(internalProperties?.build())
        return event
    }
}

extension Event {
    fileprivate func addInternalProperties(_ internalProperties: [String: Any]?) {
        self.internalProperties = internalProperties
    }
}

extension HackleEventBuilder {
    @discardableResult
    func internalProperty(_ key: String, _ value: Any?) -> HackleEventBuilder {
        if internalProperties == nil {
            internalProperties = PropertiesBuilder()
        }
        
        internalProperties?.add(key, value)
        return self
    }
}
