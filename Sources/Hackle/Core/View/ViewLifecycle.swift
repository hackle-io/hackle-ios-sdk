import Foundation
import UIKit

enum ViewLifecycle {
    case onForeground(top: UIViewController?)
    case onBackground(top: UIViewController?)
    case viewWillAppear(vc: UIViewController, top: UIViewController)
    case viewDidAppear(vc: UIViewController, top: UIViewController)
    case viewWillDisappear(vc: UIViewController, top: UIViewController)
    case viewDidDisappear(vc: UIViewController, top: UIViewController)
}

extension ViewLifecycle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .onForeground(let top):
            guard let top else {
                return "onForeground(top: nil)"
            }
            return "onForeground(top: \(Screen.screenClass(top)))"
        case .viewWillAppear(let vc, let top):
            return "viewWillAppear(vc: \(Screen.screenClass(vc)), top: \(Screen.screenClass(top))"
        case .viewDidAppear(let vc, let top):
            return "viewDidAppear(vc: \(Screen.screenClass(vc)), top: \(Screen.screenClass(top))"
        case .viewWillDisappear(let vc, let top):
            return "viewWillDisappear(vc: \(Screen.screenClass(vc)), top: \(Screen.screenClass(top))"
        case .viewDidDisappear(let vc, let top):
            return "viewDidDisappear(vc: \(Screen.screenClass(vc)), top: \(Screen.screenClass(top))"
        case .onBackground(let top):
            guard let top else {
                return "onBackground(top: nil)"
            }
            return "onBackground(top: \(Screen.screenClass(top)))"
        }
    }
}
