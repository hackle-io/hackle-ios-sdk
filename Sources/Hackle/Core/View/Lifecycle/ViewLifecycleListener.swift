import Foundation
import UIKit

protocol ViewLifecycleListener {
    func onLifecycle(lifecycle: ViewLifecycle, timestamp: Date)
}
