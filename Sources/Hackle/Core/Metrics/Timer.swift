//
//  Timer.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation

protocol Timer: Metric {

    func count() -> Int64

    func totalTime(unit: TimeUnit) -> Double

    func max(unit: TimeUnit) -> Double

    func mean(unit: TimeUnit) -> Double

    func record(amount: Double, unit: TimeUnit)
}

extension Timer {

    func mean(unit: TimeUnit) -> Double {
        let count = count()
        return count == 0 ? 0.0 : totalTime(unit: unit) / Double(count)
    }

    func measure() -> [Measurement] {
        [
            Measurement(field: .count, valueSupplier: { Double(count()) }),
            Measurement(field: .total, valueSupplier: { totalTime(unit: .milliseconds) }),
            Measurement(field: .max, valueSupplier: { max(unit: .milliseconds) }),
            Measurement(field: .mean, valueSupplier: { mean(unit: .milliseconds) })
        ]
    }
}

class TimerBuilder {

    private let name: String
    private var tags = [String: String]()

    init(name: String) {
        self.name = name
    }

    func tags(_ tags: [String: String]) -> TimerBuilder {
        for (key, value) in tags {
            self.tags[key] = value
        }
        return self
    }

    func tag(_ key: String, _ value: String) -> TimerBuilder {
        tags[key] = value
        return self
    }

    func register(registry: MetricRegistry) -> Timer {
        let id = MetricId(name: name, tags: tags, type: .timer)
        return registry.timer(id: id)
    }
}

class TimerSample {

    private let clock: Clock
    private let startTick: UInt64

    private init(clock: Clock) {
        self.clock = clock
        startTick = clock.tick()
    }

    static func start(clock: Clock = SystemClock.shared) -> TimerSample {
        TimerSample(clock: clock)
    }

    func stop(timer: Timer) {
        let durationNanos = Double(clock.tick() - startTick)
        timer.record(amount: durationNanos, unit: .nanoseconds)
    }
}
