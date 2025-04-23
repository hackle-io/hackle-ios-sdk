//
// Created by yong on 2020/12/11.
//

import Foundation

protocol UserEventProcessor {
    func process(event: UserEvent)
    func initialize()
    func start()
    func stop()
    func flush()
}

extension UserEventProcessor {
    func process(events: [UserEvent]) {
        for event in events {
            process(event: event)
        }
    }
}

class DefaultUserEventProcessor: UserEventProcessor, AppStateListener {

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.DefaultUserEventProcessor.Lock")

    private let eventFilters: [UserEventFilter]
    private let eventDecorator: [UserEventDecorator]
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
    private let screenUserEventDecorator: UserEventDecorator

    private var flushingJob: ScheduledJob? = nil

    init(
        eventFilters: [UserEventFilter],
        eventDecorator: [UserEventDecorator],
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
        appStateManager: AppStateManager,
        screenUserEventDecorator: UserEventDecorator
    ) {
        self.eventFilters = eventFilters
        self.eventDecorator = eventDecorator
        self.eventPublisher = eventPublisher
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
        self.screenUserEventDecorator = screenUserEventDecorator
    }

    func process(event: UserEvent) {
        // MARK: screen decorator는 queue에 들어가기 전에 추가해야 한다.
        // - 큐에 들어간 후 처리되기 전에 screen이 바뀔 수 있기 때문
        let decoratedEvent = screenUserEventDecorator.decorate(event: event)
        eventQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            self.addEventInternal(event: decoratedEvent)
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

    func onState(state: AppState, timestamp: Date) {
        Log.debug("UserEventProcessor.onState(state: \(state))")
        switch state {
        case .foreground:
            start()
        case .background:
            stop()
        }
    }

    private func addEventInternal(event: UserEvent) {
        updateEvent(event: event)
        if eventFilters.contains(where: { filter in filter.isBlock(event: event) }) {
            return
        }
        
        let decoratedEvent = eventDecorator.reduce(event) { (userEvent, eventDecorator) in
            eventDecorator.decorate(event: userEvent)
        }

        saveEvent(event: decoratedEvent)
        eventPublisher.publish(event: decoratedEvent)
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
