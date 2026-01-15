//
//  Screen.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/25/25.
//

import Foundation
import UIKit

/// Represents a screen in the application for tracking purposes.
///
/// Used for screen tracking
@objc(HackleScreen)
public class Screen: NSObject {
    let name: String
    let className: String
    let properties: [String: Any]

    init(name: String, className: String, properties: [String: Any]) {
        self.name = name
        self.className = className
        self.properties = properties
    }
    
    /// Creates a new screen instance.
    ///
    /// - Parameters:
    ///   - name: The name of the screen
    ///   - className: The class name of the screen/view controller
    @available(*, deprecated, message: "Screen(name: String, className:String) is deprecated. Use Screen.builder() instead")
    @objc public init(name: String, className: String) {
        self.name = name
        self.className = className
        self.properties = [:]
    }
    
    public override var description: String {
        "Screen(name: \(name), class: \(className))"
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Screen {
            return self.name == other.name && self.className == other.className
        }
        return false
    }
    
    /// Creates a new screen builder with the screen name.
    ///
    /// - Parameter key: The event key identifier
    /// - Returns: A ``HackleScreenBuilder`` instance for creating events
    @objc public static func builder(name: String, className: String) -> HackleScreenBuilder {
        HackleScreenBuilder(name: name, className: className)
    }
}

extension Screen {
    static func from(_ vc: UIViewController) -> Screen {
        let name = screenClass(vc)
        return Screen.builder(name: name, className: name).build()
    }

    static func screenClass(_ viewController: UIViewController) -> String {
        let className = String(describing: type(of: viewController))

        if !className.isEmpty {
            return className
        }
        return "Unknown"
    }
}

/// Builder for creating ``Screen`` instances.
///
/// Use this builder to construct screen with specific screen name
@objc public class HackleScreenBuilder: NSObject {
    private let name: String
    private let className: String
    private var properties: PropertiesBuilder = PropertiesBuilder()
    
    init(name: String, className: String) {
        self.name = name
        self.className = className
    }
    
    /// Adds a custom property to the screen.
    ///
    /// - Parameters:
    ///   - key: The property key
    ///   - value: The property value
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func property(_ key: String, _ value: Any?) -> HackleScreenBuilder {
        self.properties.add(key, value)
        return self
    }

    /// Adds multiple custom properties to the screen.
    ///
    /// - Parameter properties: A dictionary of property keys and values
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func properties(_ properties: [String: Any]) -> HackleScreenBuilder {
        self.properties.add(properties)
        return self
    }
    
    /// Builds an ``Screen`` instance with the configured values.
    ///
    /// - Returns: A new ``Screen`` instance
    @objc public func build() -> Screen {
        Screen(name: name, className: className, properties: properties.build())
    }
}
