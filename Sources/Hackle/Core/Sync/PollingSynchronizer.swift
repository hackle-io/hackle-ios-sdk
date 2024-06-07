//
//  PollingSynchronizer.swift
//  Hackle
//
//  Created by yong on 2023/10/02.
//

import Foundation


class PollingSynchronizer: CompositeSynchronizer, AppStateListener {

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.PollingSynchronizer.Lock")

    private let delegate: CompositeSynchronizer
    private let scheduler: Scheduler
    private let interval: TimeInterval
    private var pollingJob: ScheduledJob? = nil

    init(delegate: CompositeSynchronizer, scheduler: Scheduler, interval: TimeInterval) {
        self.delegate = delegate
        self.scheduler = scheduler
        self.interval = interval
    }

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        delegate.sync(completion: completion)
    }

    func syncOnly(type: SynchronizerType, completion: @escaping (Result<(), Error>) -> ()) {
        delegate.syncOnly(type: type, completion: completion)
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

        lock.write { [weak self] in
            if self?.pollingJob != nil {
                return
            }

            self?.pollingJob = self?.scheduler.schedulePeriodically(delay: interval, period: interval, task: poll)
            Log.info("PollingSynchronizer started polling. Poll every \(interval)s")
        }
    }

    func stop() {
        if interval == HackleConfig.NO_POLLING {
            return
        }
        lock.write { [weak self] in
            self?.pollingJob?.cancel()
            self?.pollingJob = nil
            Log.info("PollingSynchronizer stopped polling.")
        }
    }

    func onState(state: AppState, timestamp: Date) {
        switch state {
        case .foreground:
            start()
        case .background:
            stop()
        }
    }
}
