import Foundation
import UIKit

class ViewLifecycleManager: ApplicationLifecyclePublisher, ViewLifecyclePublisher {

    static let shared = ViewLifecycleManager(
        viewManager: DefaultViewManager.shared,
        clock: SystemClock.shared
    )

    private var observers = [LifecycleObserver]()
    private var listeners = [ViewLifecycleListener]()

    private let viewManager: ViewManager
    private var queue: DispatchQueue?
    private let clock: Clock

    init(viewManager: ViewManager, clock: Clock) {
        self.viewManager = viewManager
        self.clock = clock
    }

    func initialize() {
        for observer in observers {
            observer.initialize()
        }
    }
    
    func setDispatchQueue(queue: DispatchQueue) {
        self.queue = queue
    }

    func addObserver(observer: LifecycleObserver) {
        observers.append(observer)
    }

    func addListener(listener: ViewLifecycleListener) {
        listeners.append(listener)
    }

    func didBecomeActive() {
        let top = viewManager.topViewController()
        publish(lifecycle: .didBecomeActive(top: top), timestamp: clock.now())
    }

    func didEnterBackground() {
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


    private func publish(lifecycle: ViewLifecycle, timestamp: Date) {
        execute {
            Log.debug("ViewLifecycleManager.publish(lifecycle: \(lifecycle))")
            for listener in self.listeners {
                listener.onLifecycle(lifecycle: lifecycle, timestamp: timestamp)
            }
        }
    }
    
    private func execute(_ action: @escaping () -> Void) {
        if let queue = queue {
            queue.async(execute: action)
        } else {
            action()
        }
    }
}
