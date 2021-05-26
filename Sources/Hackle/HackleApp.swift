//
// Created by yong on 2020/12/11.
//

import Foundation

/// Entry point of Hackle Sdk.
@objc public final class HackleApp: NSObject {

    private let decider: Decider
    private let workspaceFetcher: WorkspaceFetcher
    private let eventProcessor: UserEventProcessor

    @objc public var deviceId: String {
        get {
            UserDefaults.standard.computeIfAbsent(key: HackleApp.hackleDeviceId) { _ in UUID().uuidString }
        }
    }

    init(decider: Decider, workspaceFetcher: WorkspaceFetcher, eventProcessor: UserEventProcessor) {
        self.decider = decider
        self.workspaceFetcher = workspaceFetcher
        self.eventProcessor = eventProcessor
    }

    @objc public func variation(experimentKey: Int, defaultVariation: String = "A") -> String {
        return variation(experimentKey: experimentKey, userId: deviceId, defaultVariation: defaultVariation)
    }

    @objc public func variation(experimentKey: Int, userId: String, defaultVariation: String = "A") -> String {
        return variation(experimentKey: experimentKey, user: Hackle.user(id: userId), defaultVariation: defaultVariation)
    }

    @objc public func variation(experimentKey: Int, user: User, defaultVariation: String = "A") -> String {

        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return defaultVariation
        }

        guard let experiment = workspace.getExperimentOrNil(experimentKey: Int64(experimentKey)) else {
            return defaultVariation
        }

        let decision = decider.decide(experiment: experiment, user: user)
        switch decision {
        case .NotAllocated:
            return defaultVariation
        case .ForcedAllocated(let variationKey):
            return variationKey
        case .NaturalAllocated(let variation):
            let userEvent = UserEvents.exposure(user: user, experiment: experiment, variation: variation)
            eventProcessor.process(event: userEvent)
            return variation.key
        }
    }

    @objc public func track(eventKey: String) {
        track(eventKey: eventKey, userId: deviceId)
    }

    @objc public func track(eventKey: String, userId: String) {
        track(eventKey: eventKey, user: Hackle.user(id: userId))
    }

    @objc public func track(eventKey: String, user: User) {
        track(event: Hackle.event(key: eventKey), user: user)
    }

    @objc public func track(event: Event) {
        track(event: event, userId: deviceId)
    }

    @objc public func track(event: Event, userId: String) {
        track(event: event, user: Hackle.user(id: userId))
    }

    @objc public func track(event: Event, user: User) {
        guard let workspace = workspaceFetcher.getWorkspaceOrNil() else {
            return
        }
        let eventType = workspace.getEventTypeOrNil(eventTypeKey: event.key) ?? UndefinedEventType(key: event.key)
        let userEvent = UserEvents.track(user: user, eventType: eventType, event: event)
        eventProcessor.process(event: userEvent)
    }
}

extension HackleApp {

    private static let hackleDeviceId = "hackle_device_id"

    func initialize(completion: @escaping () -> ()) {
        eventProcessor.start()
        workspaceFetcher.fetchFromServer {
            Log.info("Hackle \(Version.CURRENT) started")
            completion()
        }
    }

    static func create(sdkKey: String) -> HackleApp {

        let sdk = Sdk(key: sdkKey, name: "ios-sdk", version: Version.CURRENT)
        let httpClient = DefaultHttpClient(sdk: sdk)

        let httpWorkspaceFetcher = DefaultHttpWorkspaceFetcher(
            sdkBaseUrl: URL(string: "https://sdk.hackle.io")!,
            httpClient: httpClient
        )
        let workspaceFetcher = CachedWorkspaceFetcher(httpWorkspaceFetcher: httpWorkspaceFetcher)

        let eventDispatcher = DefaultUserEventDispatcher(
            eventBaseUrl: URL(string: "https://event.hackle.io")!,
            httpClient: httpClient
        )
        let eventProcessor = DefaultUserEventProcessor(
            eventQueue: ConcurrentArray(),
            eventDispatcher: eventDispatcher,
            eventDispatchSize: 10,
            flushScheduler: DispatchSourceTimerScheduler(),
            flushInterval: 60
        )

        DefaultAppNotificationObserver.instance.addListener(listener: eventProcessor)

        return HackleApp(
            decider: BucketingDecider(),
            workspaceFetcher: workspaceFetcher,
            eventProcessor: eventProcessor
        )
    }
}
