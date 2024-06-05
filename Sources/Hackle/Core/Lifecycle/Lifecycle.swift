import Foundation
import UIKit

enum Lifecycle {
    case didBecomeActive(top: UIViewController?)
    case didEnterBackground(top: UIViewController?)
    case viewWillAppear(vc: UIViewController, top: UIViewController)
    case viewDidAppear(vc: UIViewController, top: UIViewController)
    case viewWillDisappear(vc: UIViewController, top: UIViewController)
    case viewDidDisappear(vc: UIViewController, top: UIViewController)
}

extension Lifecycle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .didBecomeActive(let top):
            guard let top else {
                return "didBecomeActive(top: nil)"
            }
            return "didBecomeActive(top: \(Screen.screenClass(top)))"
        case .viewWillAppear(let vc, let top):
            return "viewWillAppear(vc: \(Screen.screenClass(vc)), top: \(Screen.screenClass(top))"
        case .viewDidAppear(let vc, let top):
            return "viewDidAppear(vc: \(Screen.screenClass(vc)), top: \(Screen.screenClass(top))"
        case .viewWillDisappear(let vc, let top):
            return "viewWillDisappear(vc: \(Screen.screenClass(vc)), top: \(Screen.screenClass(top))"
        case .viewDidDisappear(let vc, let top):
            return "viewDidDisappear(vc: \(Screen.screenClass(vc)), top: \(Screen.screenClass(top))"
        case .didEnterBackground(let top):
            guard let top else {
                return "didEnterBackground(top: nil)"
            }
            return "didEnterBackground(top: \(Screen.screenClass(top)))"
        }
    }
}
