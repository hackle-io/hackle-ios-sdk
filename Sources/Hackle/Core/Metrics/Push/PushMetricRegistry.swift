//
//  PushMetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class PushMetricRegistry: MetricRegistry, AppStateListener {

    private let lock = ReadWriteLock(label: "io.hackle.PushMetricRegistry.Lock")

    private var publishingJob: ScheduledJob? = nil

    private let scheduler: Scheduler
    private let pushInterval: TimeInterval

    init(scheduler: Scheduler, pushInterval: TimeInterval) {
        self.scheduler = scheduler
        self.pushInterval = pushInterval
        super.init()
    }

    final func onState(state: AppState, timestamp: Date) {
        Log.debug("PushMetricRegistry.onState(state: \(state))")
        switch state {
        case .foreground:
            start()
        case .background:
            stop()
        }
    }

    func publish() {
    }

    final func start() {
        lock.write { [weak self] in

            if self?.publishingJob != nil {
                return
            }

            let delay = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: pushInterval) + 0.001
            self?.publishingJob = scheduler.schedulePeriodically(delay: delay, period: pushInterval) {
                self?.publish()
            }

            Log.info("\(self?.name ?? "PushMetricRegistry") started. Publish metrics every \(pushInterval.format())")
        }

    }

    final func stop() {
        lock.write { [weak self] in
            self?.publishingJob?.cancel()
            self?.publishingJob = nil
            self?.publish()
            Log.info("\(self?.name ?? "PushMetricRegistry") stopped.")
        }
    }
}
