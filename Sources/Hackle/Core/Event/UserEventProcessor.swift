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

extension UserEventProcessor {
    func process(events: [UserEvent]) {
        for event in events {
            process(event: event)
        }
    }
}

class DefaultUserEventProcessor: UserEventProcessor, AppStateChangeListener {

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.DefaultUserEventProcessor.Lock")

    private let eventDedupDeterminer: ExposureEventDedupDeterminer
    private let eventPublisher: UserEventPublisher
    private let eventQueue: DispatchQueue
    private let eventRepository: EventRepository
    private let eventRepositoryMaxSize: Int
    private let eventFlushScheduler: Scheduler
    private let eventFlushInterval: TimeInterval
    private let eventFlushThreshold: Int
    private let eventFlushMaxBatchSize: Int
    private let eventDispatcher: UserEventDispatcher
    private let sessionManager: SessionManager
    private let userManager: UserManager
    private let appStateManager: AppStateManager

    private var flushingJob: ScheduledJob? = nil

    init(
        eventDedupDeterminer: ExposureEventDedupDeterminer,
        eventPublisher: UserEventPublisher,
        eventQueue: DispatchQueue,
        eventRepository: EventRepository,
        eventRepositoryMaxSize: Int,
        eventFlushScheduler: Scheduler,
        eventFlushInterval: TimeInterval,
        eventFlushThreshold: Int,
        eventFlushMaxBatchSize: Int,
        eventDispatcher: UserEventDispatcher,
        sessionManager: SessionManager,
        userManager: UserManager,
        appStateManager: AppStateManager
    ) {
        self.eventPublisher = eventPublisher
        self.eventDedupDeterminer = eventDedupDeterminer
        self.eventQueue = eventQueue
        self.eventRepository = eventRepository
        self.eventRepositoryMaxSize = eventRepositoryMaxSize
        self.eventFlushScheduler = eventFlushScheduler
        self.eventFlushThreshold = eventFlushThreshold
        self.eventFlushInterval = eventFlushInterval
        self.eventFlushMaxBatchSize = eventFlushMaxBatchSize
        self.eventDispatcher = eventDispatcher
        self.sessionManager = sessionManager
        self.userManager = userManager
        self.appStateManager = appStateManager
    }

    func process(event: UserEvent) {
        eventQueue.async {
            self.addEventInternal(event: event)
            self.eventPublisher.publish(event: event)
        }
    }

    private func setScreen(to event: UserEvent) {
        let currentScreen = appStateManager.screen { newScreen in
            event.setScreen(newScreen)
        }
        event.setScreen(currentScreen)
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
        Log.debug("DefaultUserEventProcessor initialized.")
    }

    func start() {
        lock.write { [weak self] in
            if self?.flushingJob != nil {
                return
            }
            self?.flushingJob = eventFlushScheduler.schedulePeriodically(delay: eventFlushInterval, period: eventFlushInterval) {
                self?.flush()
            }
            Log.info("UserEventProcessor started. Flush events every \(eventFlushInterval)s")
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

    func onChanged(state: AppState, timestamp: Date) {
        switch state {
        case .foreground:
            start()
        case .background:
            stop()
        }
    }

    private func addEventInternal(event: UserEvent) {
        updateEvent(event: event)
        if eventDedupDeterminer.isDedupTarget(event: event) {
            return
        }
        let decoratedEvent = decorateSession(event: event)
        saveEvent(event: decoratedEvent)
    }

    private func updateEvent(event: UserEvent) {
        if SessionEventTracker.isSessionEvent(event: event) {
            return
        }

        if appStateManager.currentState == .foreground {
            sessionManager.updateLastEventTime(timestamp: event.timestamp)
        } else {
            // Corner case when an event is processed between background and foreground
            sessionManager.startNewSessionIfNeeded(user: userManager.currentUser, timestamp: event.timestamp)
        }
    }

    private func decorateSession(event: UserEvent) -> UserEvent {

        if event.user.sessionId != nil {
            return event
        }

        guard let session = sessionManager.currentSession else {
            return event
        }

        let decoratedUser = event.user.toBuilder()
            .identifier(.session, session.id, overwrite: false)
            .build()
        return event.with(user: decoratedUser)
    }

    private func saveEvent(event: UserEvent) {
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
}
