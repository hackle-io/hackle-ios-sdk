import Foundation
import UIKit

struct Screen: Equatable {
    let name: String
    let className: String // ScreenClass
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


extension Screen: CustomStringConvertible {
    public var description: String {
        "Screen(name: \(name), class: \(className))"
    }
}
