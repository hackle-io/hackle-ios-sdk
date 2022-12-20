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

class DefaultUserEventProcessor: UserEventProcessor, AppInitializeListener, AppNotificationListener {

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
    private let userManager: UserManager
    private let sessionManager: SessionManager

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
        eventDispatcher: UserEventDispatcher,
        userManager: UserManager,
        sessionManager: SessionManager
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
        self.userManager = userManager
        self.sessionManager = sessionManager
    }

    func process(event: UserEvent) {
        eventQueue.async {
            self.addEventInternal(event: event)
        }
    }

    func flush() {
        eventQueue.async {
            self.flushInternal()
        }
    }

    func initialize() {
        start()
        let events = eventRepository.findAllBy(status: .flushing)
        if !events.isEmpty {
            eventRepository.update(events: events, status: .pending)
        }
    }

    func start() {
        lock.write { [weak self] in
            if self?.flushingJob != nil {
                return
            }
            self?.flushingJob = eventFlushScheduler.schedulePeriodically(delay: eventFlushInterval, period: eventFlushInterval) {
                self?.flush()
            }
            Log.info("UserEventProcessor started. Flush events every \(eventFlushInterval.format())")
        }
    }

    func stop() {
        lock.write { [weak self] in
            self?.flushingJob?.cancel()
            self?.flushingJob = nil
            self?.flush()
            Log.info("UserEventProcessor stopped. Flush pending events")
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

    func onInitialized() {
        eventQueue.async { [weak self] in
            self?.initialize()
        }
    }

    func onNotified(notification: AppNotification, timestamp: Date) {
        switch notification {
        case .didBecomeActive:
            start()
        case .didEnterBackground:
            stop()
        }
    }

    private func addEventInternal(event: UserEvent) {
        userManager.updateUser(user: event.user)
        sessionManager.updateLastEventTime(timestamp: event.timestamp)

        if eventDedupDeterminer.isDedupTarget(event: event) {
            return
        }

        let newEvent = decorateSession(event: event)

        eventRepository.save(event: newEvent)

        let totalCount = eventRepository.count()
        if totalCount > eventRepositoryMaxSize {
            eventRepository.deleteOldEvents(count: eventFlushMaxBatchSize)
        }

        let pendingCount = eventRepository.countBy(status: .pending)
        if pendingCount >= eventFlushThreshold && pendingCount % eventFlushThreshold == 0 {
            dispatch(limit: eventFlushMaxBatchSize)
        }
    }

    private func decorateSession(event: UserEvent) -> UserEvent {
        guard let session = sessionManager.currentSession else {
            return event
        }

        if event.user.sessionId != nil {
            return event
        }

        let identifiers = IdentifiersBuilder()
            .add(identifiers: event.user.identifiers)
            .add(type: .session, value: session.id)
            .build()

        let newUser = event.user.with(identifiers: identifiers)
        return event.with(user: newUser)
    }

    private func flushInternal() {
        dispatch(limit: eventFlushMaxBatchSize)
    }
}
