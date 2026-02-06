import Foundation
import UIKit
@testable import Hackle

class MockViewManager: ViewManager {

    var top: UIViewController? = nil
    var isOwnedView: Bool = false

    @MainActor func topViewController() -> UIViewController? {
        top
    }

    func isOwnedView(vc: UIViewController) -> Bool {
        isOwnedView
    }
}
