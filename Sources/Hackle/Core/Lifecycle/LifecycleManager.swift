import Foundation
import UIKit

class LifecycleManager: LifecyclePublisher {

    static let shared = LifecycleManager(
        viewManager: DefaultViewManager.shared,
        clock: SystemClock.shared
    )

    private let initialized: AtomicReference<Bool> = AtomicReference(value: false)
    private var listeners = [LifecycleListener]()

    private let viewManager: ViewManager
    private let clock: Clock

    init(viewManager: ViewManager, clock: Clock) {
        self.viewManager = viewManager
        self.clock = clock
    }

    func initialize() {
        guard initialized.compareAndSet(expect: false, update: true) else {
            Log.debug("LifecycleManager already initialized.")
            return
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
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

    func addListener(listener: LifecycleListener) {
        listeners.append(listener)
    }

    @objc func didBecomeActive() {
        let top = viewManager.topViewController()
        publish(lifecycle: .didBecomeActive(top: top), timestamp: clock.now())
    }

    @objc func didEnterBackground() {
        let top = viewManager.topViewController()
        publish(lifecycle: .didEnterBackground(top: top), timestamp: clock.now())
    }

    func viewWillAppear(vc: UIViewController) {
        guard let top = viewManager.topViewController() else {
            return
        }
        publish(lifecycle: .viewWillAppear(vc: vc, top: top), timestamp: clock.now())
    }

    func viewDidAppear(vc: UIViewController) {
        guard let top = viewManager.topViewController() else {
            return
        }
        publish(lifecycle: .viewDidAppear(vc: vc, top: top), timestamp: clock.now())
    }

    func viewWillDisappear(vc: UIViewController) {
        guard let top = viewManager.topViewController() else {
            return
        }
        publish(lifecycle: .viewWillDisappear(vc: vc, top: top), timestamp: clock.now())
    }

    func viewDidDisappear(vc: UIViewController) {
        guard let top = viewManager.topViewController() else {
            return
        }
        publish(lifecycle: .viewDidDisappear(vc: vc, top: top), timestamp: clock.now())
    }


    private func publish(lifecycle: Lifecycle, timestamp: Date) {
        Log.debug("onLifecycle(lifecycle: \(lifecycle))")
        for listener in listeners {
            listener.onLifecycle(lifecycle: lifecycle, timestamp: timestamp)
        }
    }
}

extension UIViewController {
    @objc func hackle_viewWillAppear(_ animation: Bool) {
        hackle_viewWillAppear(animation)
        guard DefaultViewManager.shared.isOwnedView(vc: self) else {
            return
        }
        LifecycleManager.shared.viewWillAppear(vc: self)
    }

    @objc func hackle_viewDidAppear(_ animation: Bool) {
        hackle_viewDidAppear(animation)
        guard DefaultViewManager.shared.isOwnedView(vc: self) else {
            return
        }
        LifecycleManager.shared.viewDidAppear(vc: self)
    }

    @objc func hackle_viewWillDisappear(_ animation: Bool) {
        hackle_viewWillDisappear(animation)

        guard DefaultViewManager.shared.isOwnedView(vc: self) else {
            return
        }
        LifecycleManager.shared.viewWillDisappear(vc: self)
    }

    @objc func hackle_viewDidDisappear(_ animation: Bool) {
        hackle_viewDidDisappear(animation)
        guard DefaultViewManager.shared.isOwnedView(vc: self) else {
            return
        }
        LifecycleManager.shared.viewDidDisappear(vc: self)
    }
}
