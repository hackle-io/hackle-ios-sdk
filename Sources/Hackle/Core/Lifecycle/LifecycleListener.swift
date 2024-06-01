import Foundation
import UIKit

protocol LifecycleListener {
    func onLifecycle(lifecycle: Lifecycle, timestamp: Date)
}
