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
    
    /// Creates a new screen instance.
    ///
    /// - Parameters:
    ///   - name: The name of the screen
    ///   - className: The class name of the screen/view controller
    @objc public init(name: String, className: String) {
        self.name = name
        self.className = className
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
}

extension Screen {
    static func from(_ vc: UIViewController) -> Screen {
        let name = screenClass(vc)
        return Screen(name: name, className: name)
    }

    static func screenClass(_ viewController: UIViewController) -> String {
        let className = String(describing: type(of: viewController))

        if !className.isEmpty {
            return className
        }
        return "Unknown"
    }
}
