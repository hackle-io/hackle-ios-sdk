import Foundation
import UIKit

protocol LifecyclePublisher {
    func didBecomeActive()
    func didEnterBackground()
    func viewWillAppear(vc: UIViewController)
    func viewDidAppear(vc: UIViewController)
    func viewWillDisappear(vc: UIViewController)
    func viewDidDisappear(vc: UIViewController)
}
