import Foundation
import UIKit

protocol ViewLifecyclePublisher {
    @MainActor func viewWillAppear(vc: UIViewController)
    @MainActor func viewDidAppear(vc: UIViewController)
    @MainActor func viewWillDisappear(vc: UIViewController)
    @MainActor func viewDidDisappear(vc: UIViewController)
}
