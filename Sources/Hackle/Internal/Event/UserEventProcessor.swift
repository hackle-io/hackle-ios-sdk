//
// Created by yong on 2020/12/11.
//

import Foundation

protocol UserEventProcessor {
    func process(event: UserEvent)
    func initialize()
    func start()
    func stop()
}

class DefaultUserEventProcessor: UserEventProcessor, AppNotificationListener {

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.DefaultUserEventProcessor.Lock")

    private let eventDedupDeterminer: ExposureEventDedupDeterminer
    private let eventQueue: DispatchQueue
    private let eventRepository: EventRepository
    private let eventRepositoryMaxSize: Int
    private let eventFlushScheduler: Scheduler
    private let eventFlushInterval: TimeInterval
    private let eventFlushThreshold: Int
    private let eventFlushMaxBatchSize: Int
    private let eventDispatcher: UserEventDispatcher

    private var flushingJob: ScheduledJob? = nil

    init(
        eventDedupDeterminer: ExposureEventDedupDeterminer,
        eventQueue: DispatchQueue,
        eventRepository: EventRepository,
        eventRepositoryMaxSize: Int,
        eventFlushScheduler: Scheduler,
        eventFlushInterval: TimeInterval,
        eventFlushThreshold: Int,
        eventFlushMaxBatchSize: Int,
        eventDispatcher: UserEventDispatcher
    ) {
        self.eventDedupDeterminer = eventDedupDeterminer
        self.eventQueue = eventQueue
        self.eventRepository = eventRepository
        self.eventRepositoryMaxSize = eventRepositoryMaxSize
        self.eventFlushScheduler = eventFlushScheduler
        self.eventFlushThreshold = eventFlushThreshold
        self.eventFlushInterval = eventFlushInterval
        self.eventFlushMaxBatchSize = eventFlushMaxBatchSize
        self.eventDispatcher = eventDispatcher
    }

    func process(event: UserEvent) {

        if eventDedupDeterminer.isDedupTarget(event: event) {
            return
        }

        addEvent(event: event)
    }

    private func addEvent(event: UserEvent) {
        eventQueue.async {
            self.addEventInternal(event: event)
        }
    }

    func flush() {
        eventQueue.async {
            self.flushInternal()
        }
    }

    func onNotified(notification: AppNotification) {
        switch notification {
        case .didEnterBackground:
            stop()
        case .didBecomeActive:
            start()
        }
    }

    func initialize() {
        eventQueue.async {
            self.initializeInternal()
        }
    }

    func start() {
        lock.write {
            if flushingJob != nil {
                return
            }
            flushingJob = eventFlushScheduler.schedulePeriodically(delay: eventFlushInterval, period: eventFlushInterval) {
                self.flush()
            }
            Log.info("UserEventProcessor started. Flush events every \(eventFlushInterval.format())")
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

    private func dispatch(limit: Int) {
        if limit <= 0 {
            return
        }

        let events = eventRepository.getEventToFlush(limit: limit)
        if events.isEmpty {
            return
        }

        eventDispatcher.dispatch(events: events)
    }

    private func addEventInternal(event: UserEvent) {
        eventRepository.save(event: event)

        let totalCount = eventRepository.count()
        if totalCount > eventRepositoryMaxSize {
            eventRepository.deleteOldEvents(count: eventFlushMaxBatchSize)
        }

        let pendingCount = eventRepository.countBy(status: .pending)
        if pendingCount >= eventFlushThreshold && pendingCount % eventFlushThreshold == 0 {
            dispatch(limit: eventFlushMaxBatchSize)
        }
    }

    private func flushInternal() {
        dispatch(limit: eventFlushMaxBatchSize)
    }

    private func initializeInternal() {
        let events = eventRepository.findAllBy(status: .flushing)
        if !events.isEmpty {
            eventRepository.update(events: events, status: .pending)
        }
    }
}
