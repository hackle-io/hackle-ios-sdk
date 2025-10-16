import Foundation
import UIKit


class PollingSynchronizer: Synchronizer {

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.PollingSynchronizer.Lock")

    private let delegate: Synchronizer
    private let scheduler: Scheduler
    private let interval: TimeInterval
    private var pollingJob: ScheduledJob? = nil

    init(delegate: Synchronizer, scheduler: Scheduler, interval: TimeInterval) {
        self.delegate = delegate
        self.scheduler = scheduler
        self.interval = interval
    }

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        delegate.sync(completion: completion)
    }

    private func poll() {
        sync {
            Log.debug("PollingSynchronizer.poll")
        }
    }

    func start() {
        if interval == HackleConfig.NO_POLLING {
            return
        }

        lock.write {
            if pollingJob != nil {
                return
            }

            pollingJob = scheduler.schedulePeriodically(delay: interval, period: interval, task: poll)
            Log.info("PollingSynchronizer started polling. Poll every \(interval)s")
        }
    }

    func stop() {
        if interval == HackleConfig.NO_POLLING {
            return
        }
        lock.write {
            pollingJob?.cancel()
            pollingJob = nil
            Log.info("PollingSynchronizer stopped polling.")
        }
    }
}

extension PollingSynchronizer: ApplicationLifecycleListener {
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        Log.debug("PollingSynchronizer.onForeground")
        start()
    }
    
    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        Log.debug("PollingSynchronizer.onBackground")
        stop()
    }
}
