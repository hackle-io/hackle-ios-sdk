//
// Created by yong on 2020/12/11.
//

import Foundation

protocol UserEventProcessor {
    func process(event: UserEvent)
    func start()
    func stop()
}

class DefaultUserEventProcessor: UserEventProcessor, AppNotificationListener {

    private let lock: ReadWriteLock

    private let eventQueue: ConcurrentArray<UserEvent>
    private let eventDispatcher: UserEventDispatcher
    private let eventDispatchSize: Int
    private let flushScheduler: Scheduler
    private let flushInterval: TimeInterval
    private let eventDedupDeterminer: ExposureEventDedupDeterminer

    private var flushingJob: ScheduledJob? = nil

    init(
        eventQueue: ConcurrentArray<UserEvent>,
        eventDispatcher: UserEventDispatcher,
        eventDispatchSize: Int,
        flushScheduler: Scheduler,
        flushInterval: TimeInterval,
        eventDedupDeterminer: ExposureEventDedupDeterminer
    ) {
        self.eventQueue = eventQueue
        self.eventDispatcher = eventDispatcher
        self.eventDispatchSize = eventDispatchSize
        self.flushScheduler = flushScheduler
        self.flushInterval = flushInterval
        self.eventDedupDeterminer = eventDedupDeterminer
        self.lock = ReadWriteLock(label: "io.hackle.DefaultUserEventProcessor.Lock")
    }

    func process(event: UserEvent) {

        if eventDedupDeterminer.isDedupTarget(event: event) {
            return
        }

        eventQueue.add(event)

        if eventQueue.size >= eventDispatchSize {
            flush()
        }
    }

    func flush() {
        let pendingEvents = eventQueue.takeAll()
        if pendingEvents.isEmpty {
            return
        }
        eventDispatcher.dispatch(events: pendingEvents)
    }

    func onNotified(notification: AppNotification) {
        switch notification {
        case .didEnterBackground:
            stop()
        case .didBecomeActive:
            start()
        }
    }

    func start() {
        lock.write {
            if flushingJob != nil {
                return
            }
            flushingJob = flushScheduler.schedulePeriodically(delay: flushInterval, period: flushInterval) {
                self.flush()
            }
            Log.info("UserEventProcessor started. Flush events every \(flushInterval.format())")
        }
    }

    func stop() {
        lock.write {
            flushingJob?.cancel()
            flushingJob = nil
            Log.info("UserEventProcessor stopped. Flush pending events")
            flush()
        }
    }
}
