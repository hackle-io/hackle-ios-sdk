import Foundation
import UIKit

protocol ViewLifecyclePublisher {
    func viewWillAppear(vc: UIViewController)
    func viewDidAppear(vc: UIViewController)
    func viewWillDisappear(vc: UIViewController)
    func viewDidDisappear(vc: UIViewController)
}
