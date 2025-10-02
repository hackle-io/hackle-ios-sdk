import Foundation
import UIKit

protocol LifecycleObserver {
    func initialize()
}

class ViewLifecycleObserver: LifecycleObserver {

    private let initialized: AtomicReference<Bool> = AtomicReference(value: false)

    func initialize() {
        guard initialized.compareAndSet(expect: false, update: true) else {
            Log.debug("ViewLifecycleObserver already initialized.")
            return
        }
        swizzle(
            originalSelector: #selector(UIViewController.viewWillAppear(_:)),
            swizzledSelector: #selector(UIViewController.hackle_viewWillAppear(_:))
        )

        swizzle(
            originalSelector: #selector(UIViewController.viewDidAppear(_:)),
            swizzledSelector: #selector(UIViewController.hackle_viewDidAppear(_:))
        )
        swizzle(
            originalSelector: #selector(UIViewController.viewWillDisappear(_:)),
            swizzledSelector: #selector(UIViewController.hackle_viewWillDisappear(_:))
        )
        swizzle(
            originalSelector: #selector(UIViewController.viewDidDisappear(_:)),
            swizzledSelector: #selector(UIViewController.hackle_viewDidDisappear(_:))
        )
    }

    private func swizzle(originalSelector: Selector, swizzledSelector: Selector) {
        let controllerClass = UIViewController.self
        guard let originalMethod = class_getInstanceMethod(controllerClass, originalSelector) else {
            return
        }
        guard let swizzledMethod = class_getInstanceMethod(controllerClass, swizzledSelector) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UIViewController {
    @objc func hackle_viewWillAppear(_ animation: Bool) {
        hackle_viewWillAppear(animation)
        guard DefaultViewManager.shared.isOwnedView(vc: self) else {
            return
        }
        ViewLifecycleManager.shared.viewWillAppear(vc: self)
    }

    @objc func hackle_viewDidAppear(_ animation: Bool) {
        hackle_viewDidAppear(animation)
        guard DefaultViewManager.shared.isOwnedView(vc: self) else {
            return
        }
        ViewLifecycleManager.shared.viewDidAppear(vc: self)
    }

    @objc func hackle_viewWillDisappear(_ animation: Bool) {
        hackle_viewWillDisappear(animation)

        guard DefaultViewManager.shared.isOwnedView(vc: self) else {
            return
        }
        ViewLifecycleManager.shared.viewWillDisappear(vc: self)
    }

    @objc func hackle_viewDidDisappear(_ animation: Bool) {
        hackle_viewDidDisappear(animation)
        guard DefaultViewManager.shared.isOwnedView(vc: self) else {
            return
        }
        ViewLifecycleManager.shared.viewDidDisappear(vc: self)
    }
}
