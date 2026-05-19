//
//  PushMetricRegistry.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation
import UIKit


class PushMetricRegistry: MetricRegistry, @unchecked Sendable {

    private let queue = DispatchQueue(label: "io.hackle.metric.push", qos: .utility)
    private var publishingJob: ScheduledJob? = nil

    private let scheduler: Scheduler
    private let pushInterval: TimeInterval

    init(scheduler: Scheduler, pushInterval: TimeInterval) {
        self.scheduler = scheduler
        self.pushInterval = pushInterval
        super.init()
    }

    func publish() {
    }

    final func start() {
        queue.async { [weak self] in
            guard let self = self else { return }
            guard self.publishingJob == nil else { return }

            let delay = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: self.pushInterval) + 0.001
            self.publishingJob = self.scheduler.schedulePeriodically(delay: delay, period: self.pushInterval) { [weak self] in
                self?.publish()
            }
            Log.info("\(self.name) started. Publish metrics every \(self.pushInterval.format())")
        }
    }

    final func stop() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.publishingJob?.cancel()
            self.publishingJob = nil
            self.publish()
            Log.info("\(self.name) stopped.")
        }
    }
}

extension PushMetricRegistry: ApplicationLifecycleListener {
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        Log.debug("PushMetricRegistry.onForeground")
        start()
    }

    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        Log.debug("PushMetricRegistry.onBackground")
        stop()
    }
}
