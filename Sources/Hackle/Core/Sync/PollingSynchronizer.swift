import Foundation


class PollingSynchronizer: Synchronizer, AppStateListener {

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

    func onState(state: AppState, timestamp: Date) {
        Log.debug("PollingSynchronizer.onState(state: \(state))")
        switch state {
        case .foreground:
            start()
        case .background:
            stop()
        }
    }
}
