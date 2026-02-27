import Foundation
import UIKit

protocol ViewManager {
    @MainActor func topViewController() -> UIViewController?
    func isOwnedView(vc: UIViewController) -> Bool
}

class DefaultViewManager: ViewManager, @unchecked Sendable {

    static let shared = DefaultViewManager()

    @MainActor func topViewController() -> UIViewController? {
        UIUtils.topViewController
    }

    func isOwnedView(vc: UIViewController) -> Bool {
        if vc is HackleViewController {
            return false
        }
        let viewControllerBundlePath = Bundle(for: vc.classForCoder).bundleURL.resolvingSymlinksInPath().path
        let mainBundlePath = Bundle.main.bundleURL.resolvingSymlinksInPath().path
        return viewControllerBundlePath.hasPrefix(mainBundlePath)
    }
}
