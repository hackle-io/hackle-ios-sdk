import Foundation
import UIKit

class ViewLifecycleManager: ViewLifecyclePublisher {

    static let shared = ViewLifecycleManager(
        viewManager: DefaultViewManager.shared,
        clock: SystemClock.shared
    )

    private var listeners = [ViewLifecycleListener]()

    private let viewManager: ViewManager
    private var queue: DispatchQueue?
    private let clock: Clock

    init(viewManager: ViewManager, clock: Clock) {
        self.viewManager = viewManager
        self.clock = clock
    }
    
    func setDispatchQueue(queue: DispatchQueue) {
        self.queue = queue
    }

    func addListener(listener: ViewLifecycleListener) {
        listeners.append(listener)
    }

    func viewWillAppear(vc: UIViewController) {
        guard let top = viewManager.topViewController(),
              viewManager.isOwnedView(vc: top) else {
            return
        }
        publish(lifecycle: .viewWillAppear(vc: vc, top: top))
    }

    func viewDidAppear(vc: UIViewController) {
        guard let top = viewManager.topViewController(),
              viewManager.isOwnedView(vc: top) else {
            return
        }
        publish(lifecycle: .viewDidAppear(vc: vc, top: top))
    }

    func viewWillDisappear(vc: UIViewController) {
        guard let top = viewManager.topViewController(),
              viewManager.isOwnedView(vc: top) else {
            return
        }
        publish(lifecycle: .viewWillDisappear(vc: vc, top: top))
    }

    func viewDidDisappear(vc: UIViewController) {
        guard let top = viewManager.topViewController(),
              viewManager.isOwnedView(vc: top) else {
            return
        }
        publish(lifecycle: .viewDidDisappear(vc: vc, top: top))
    }


    private func publish(lifecycle: ViewLifecycle) {
        execute {
            Log.debug("ViewLifecycleManager.publish(lifecycle: \(lifecycle))")
            let timestamp = self.clock.now()
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
