import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


/// DefaultSessionManager.currentSession / lastEventTime 에 대한 data race 재현 스펙.
/// -enableThreadSanitizer YES 로 실행할 것.
class SessionManagerRaceSpecs: QuickSpec {
    override class func spec() {

        it("session events complete while a user update listener is paused on another thread") {
            let userManager = makeUserManager()
            let pausedListener = PausedUserListener()
            let sessionManager = makeSessionManager(userManager: userManager)
            let core = RecordingCore()
            sessionManager.addListener(listener: SessionEventTracker(userManager: userManager, core: core))
            // 사용자 락을 보유한 콜백을 멈춰 세션 이벤트의 역방향 락 의존성을 검증한다.
            // 여기서는 세션 리스너를 사용자에 연결하지 않아 회귀 시에도 락을 풀고 종료할 수 있다.
            userManager.addListener(listener: pausedListener)
            let initialUser = userManager.currentUser
            _ = sessionManager.startNewSession(oldUser: initialUser, newUser: initialUser, timestamp: Date(timeIntervalSince1970: 1))

            let userDone = DispatchSemaphore(value: 0)
            Task.detached {
                await userManager.setUserId(userId: "new").value
                userDone.signal()
            }
            let entered = pausedListener.entered.wait(timeout: .now() + 5)
            expect(entered) == DispatchTimeoutResult.success
            guard entered == .success else {
                pausedListener.release.signal()
                return
            }

            let sessionDone = DispatchSemaphore(value: 0)
            DispatchQueue.global().async {
                _ = sessionManager.startNewSession(oldUser: initialUser, newUser: initialUser, timestamp: Date(timeIntervalSince1970: 2))
                sessionDone.signal()
            }

            // SessionEventTracker가 사용자 락을 다시 요구하면 여기서 시간 초과한다.
            // 검증 후 사용자 락을 풀어 실패한 경우에도 작업이 종료되게 한다.
            let completedWhilePaused = sessionDone.wait(timeout: .now() + 5)
            pausedListener.release.signal()
            expect(completedWhilePaused) == DispatchTimeoutResult.success
            if completedWhilePaused == .timedOut {
                expect(sessionDone.wait(timeout: .now() + 5)) == DispatchTimeoutResult.success
            }
            let userCompleted = userDone.wait(timeout: .now() + 5)
            expect(userCompleted) == DispatchTimeoutResult.success
            guard userCompleted == .success else { return }
            expect(userManager.currentUser.userId) == "new"
            expect(core.trackedCount) == 3
        }

        it("resumed async user updates preserve listener order with concurrent sessions and in-app message delays") {
            let userManager = makeUserManager()
            let sessionManager = makeSessionManager(userManager: userManager)
            let sessionListener = RaceSessionListener()
            let userListener = RecordingUserListener()
            let core = RecordingCore()
            let scheduler = RecordingDelayScheduler()
            let delayManager = DefaultInAppMessageDelayManager(scheduler: scheduler)
            let inAppMessageManager = InAppMessageManager(
                triggerProcessor: MockInAppMessageTriggerProcessor(),
                resetProcessor: DefaultInAppMessageResetProcessor(
                    identifierChecker: DefaultInAppMessageIdentifierChecker(), delayManager: delayManager
                )
            )
            // 실제 사용 경로와 동일하게 공개 및 동시 실행 전에 등록을 완료한다.
            sessionManager.addListener(listener: SessionEventTracker(userManager: userManager, core: core))
            sessionManager.addListener(listener: sessionListener)
            userManager.addListener(listener: sessionManager)
            userManager.addListener(listener: inAppMessageManager)
            userManager.addListener(listener: userListener)
            let initialUser = userManager.currentUser
            _ = sessionManager.startNewSession(oldUser: initialUser, newUser: initialUser, timestamp: Date(timeIntervalSince1970: 1))
            let initialRequest = InAppMessageEntity.schedule(dispatchId: "initial").toRequest(type: .triggered, requestedAt: Date())
            _ = delayManager.delay(request: initialRequest)

            let iterations = 200
            let group = DispatchGroup()
            for writer in 0..<2 {
                group.enter()
                Task.detached {
                    for i in 0..<iterations {
                        // 비동기 조회가 다른 실행 문맥에서 완료된 후 setUserId를 호출한다.
                        let userId: String = await withCheckedContinuation { continuation in
                            DispatchQueue.global().async {
                                continuation.resume(returning: "\(writer)-\(i)")
                            }
                        }
                        await userManager.setUserId(userId: userId).value
                    }
                    group.leave()
                }
            }
            DispatchQueue.global().async(group: group) {
                for i in 0..<iterations {
                    _ = sessionManager.startNewSession(oldUser: initialUser, newUser: initialUser, timestamp: Date(timeIntervalSince1970: Double(100 + i)))
                    _ = userManager.hackleUser(user: initialUser)
                    _ = userManager.currentUser
                }
            }
            DispatchQueue.global().async(group: group) {
                for i in 0..<iterations {
                    let request = InAppMessageEntity.schedule(dispatchId: "delay-\(i)").toRequest(type: .triggered, requestedAt: Date())
                    _ = delayManager.delay(request: request)
                }
            }

            let completed = group.wait(timeout: .now() + 30)
            expect(completed) == DispatchTimeoutResult.success
            guard completed == .success else { return }
            // 마지막 사용자 변경으로 경쟁 중 등록된 나머지 지연 작업도 취소한다.
            let finalSync = userManager.setUserId(userId: "final")
            let syncDone = DispatchSemaphore(value: 0)
            Task.detached {
                await finalSync.value
                syncDone.signal()
            }
            expect(syncDone.wait(timeout: .now() + 5)) == DispatchTimeoutResult.success

            let transitions = userListener.transitions
            expect(transitions.count) == 2 * iterations + 1
            expect(transitions.first?.old) == "init"
            expect(transitions.last?.new) == "final"
            expect(Array(transitions.dropFirst().map(\.old))) == Array(transitions.dropLast().map(\.new))
            expect(Set(transitions.map(\.new)).count) == transitions.count
            expect(userManager.currentUser.userId) == "final"
            expect(scheduler.tasks.count) == iterations + 1
            expect(scheduler.tasks.allSatisfy { $0.cancelCount.get() == 1 }) == true
            expect(delayManager.cancelAll()).to(beEmpty())

            let records = sessionListener.records
            let startedIds = records.filter { $0.hasPrefix("start:") }.map { String($0.dropFirst(6)) }
            expect(startedIds.count) == 3 * iterations + 2
            var expected = [String]()
            for id in startedIds.dropLast() {
                expected.append(contentsOf: ["start:\(id)", "end:\(id)"])
            }
            expected.append("start:\(startedIds.last ?? "missing")")
            expect(records) == expected
            expect(startedIds.last) == sessionManager.currentSession?.id
            expect(core.trackedCount) == 2 * startedIds.count - 1
        }

        it("DefaultSessionManager: concurrent startNewSessionIfNeeded (setUserId thread vs coreQueue)") {
            let listener = RaceSessionListener()
            let repository = MemoryKeyValueRepository()
            let sut = DefaultSessionManager(
                userManager: MockUserManager(),
                keyValueRepository: repository,
                applicationLifecycleManager: MockApplicationLifecycleManager(currentState: .foreground),
                sessionPolicy: HackleSessionPolicy.builder().persistCondition(.alwaysNewSession).build()
            )
            sut.addListener(listener: listener)
            let user = User.builder().deviceId("device1").userId("A").build()
            sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 1))

            let threads = 4
            let iterations = 500
            DispatchQueue.concurrentPerform(iterations: threads) { t in
                for i in 0..<iterations {
                    let newUser = User.builder().deviceId("device1").userId("\(t)-\(i)").build()
                    let timestamp = Date(timeIntervalSince1970: Double(1_000 + t * iterations + i))
                    sut.startNewSessionIfNeeded(context: SessionContext.of(oldUser: user, newUser: newUser, timestamp: timestamp))
                    _ = sut.currentSession
                    _ = sut.lastEventTime
                    if i % 50 == 0 {
                        sut.onBackground(nil, timestamp: timestamp)
                    }
                }
            }

            let records = listener.records
            let startedIds = records.filter { $0.hasPrefix("start:") }.map { String($0.dropFirst("start:".count)) }

            var expected = [String]()
            for (index, id) in startedIds.enumerated() {
                expected.append("start:\(id)")
                if index < startedIds.count - 1 {
                    expected.append("end:\(id)")
                }
            }

            expect(startedIds.count) == 1 + threads * iterations
            expect(Set(startedIds).count) == startedIds.count
            expect(records.count) == 2 * startedIds.count - 1
            expect(records) == expected
            expect(startedIds.last) == sut.currentSession?.id
            expect(repository.getString(key: "session_id")) == sut.currentSession?.id
        }

        it("DefaultSessionManager + LocalUserManager: setUserId vs startNewSessionIfNeeded does not deadlock") {
            let device = MockDevice(id: "device1", properties: [:])
            let userManager = LocalUserManager(
                device: device,
                bundleInfo: BundleInfoImpl(),
                repository: UserRepository(repository: MemoryKeyValueRepository()),
                cohortFetcher: EmptyCohortFetcher(),
                targetFetcher: EmptyTargetEventFetcher(),
                clock: FixedClock(date: Date(timeIntervalSince1970: 42))
            )
            userManager.initialize(user: User.builder().deviceId("device1").userId("init").build())

            let sessionManager = DefaultSessionManager(
                userManager: userManager,
                keyValueRepository: MemoryKeyValueRepository(),
                applicationLifecycleManager: MockApplicationLifecycleManager(currentState: .foreground),
                sessionPolicy: HackleSessionPolicy.builder().persistCondition(.alwaysNewSession).build()
            )
            let core = RecordingCore()
            sessionManager.addListener(listener: SessionEventTracker(userManager: userManager, core: core))
            userManager.addListener(listener: sessionManager)
            sessionManager.initialize()
            let initialUser = userManager.currentUser
            sessionManager.startNewSession(oldUser: initialUser, newUser: initialUser, timestamp: Date(timeIntervalSince1970: 1))

            let iterations = 1_000
            let gate = DispatchSemaphore(value: 0)
            let group = DispatchGroup()

            DispatchQueue.global(qos: .userInitiated).async(group: group) {
                gate.wait()
                for i in 0..<iterations {
                    _ = userManager.setUserId(userId: "A-\(i)")
                }
            }

            DispatchQueue.global(qos: .userInitiated).async(group: group) {
                gate.wait()
                let oldUser = User.builder().deviceId("device1").userId("B").build()
                for i in 0..<iterations {
                    let newUser = User.builder().deviceId("device1").userId("B-\(i)").build()
                    let timestamp = Date(timeIntervalSince1970: Double(1_000 + i))
                    sessionManager.startNewSessionIfNeeded(context: SessionContext.of(oldUser: oldUser, newUser: newUser, timestamp: timestamp))
                }
            }

            gate.signal()
            gate.signal()
            let result = group.wait(timeout: .now() + 30)

            expect(result) == DispatchTimeoutResult.success
            expect(core.trackedCount) == 1 + 4 * iterations
        }
    }
    private static func makeUserManager() -> LocalUserManager {
        let manager = LocalUserManager(
            device: MockDevice(id: "device1", properties: [:]),
            bundleInfo: BundleInfoImpl(),
            repository: UserRepository(repository: MemoryKeyValueRepository()),
            cohortFetcher: EmptyCohortFetcher(),
            targetFetcher: EmptyTargetEventFetcher(),
            clock: FixedClock(date: Date(timeIntervalSince1970: 42))
        )
        manager.initialize(user: User.builder().deviceId("device1").userId("init").build())
        return manager
    }

    private static func makeSessionManager(userManager: UserManager) -> DefaultSessionManager {
        let manager = DefaultSessionManager(
            userManager: userManager,
            keyValueRepository: MemoryKeyValueRepository(),
            applicationLifecycleManager: MockApplicationLifecycleManager(currentState: .foreground),
            sessionPolicy: HackleSessionPolicy.builder().persistCondition(.alwaysNewSession).build()
        )
        manager.initialize()
        return manager
    }
}

private final class PausedUserListener: UserListener {
    let entered = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        entered.signal()
        release.wait()
    }

    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {}
}

private final class RecordingUserListener: UserListener {
    private let lock = NSLock()
    private var recorded: [(old: String?, new: String?)] = []

    var transitions: [(old: String?, new: String?)] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append((oldUser.userId, newUser.userId))
    }

    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {}
}

private final class RecordingDelayScheduler: InAppMessageDelayScheduler {
    private(set) var tasks: [RecordingDelayTask] = []

    func schedule(delay: InAppMessageDelay) -> InAppMessageDelayTask {
        let task = RecordingDelayTask(delay: delay)
        tasks.append(task)
        return task
    }
}

private final class RecordingDelayTask: InAppMessageDelayTask {
    let delay: InAppMessageDelay
    let cancelCount = AtomicReference(value: 0)

    init(delay: InAppMessageDelay) {
        self.delay = delay
    }

    func cancel() {
        cancelCount.set(newValue: cancelCount.get() + 1)
    }
}

private class RaceSessionListener: SessionListener {

    private let lock = NSLock()
    private var recorded = [String]()

    var records: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func onSessionStarted(session: Session, user: User, timestamp: Date) {
        append("start:\(session.id)")
    }

    func onSessionEnded(session: Session, user: User, timestamp: Date) {
        append("end:\(session.id)")
    }

    private func append(_ record: String) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(record)
    }
}

private final class RecordingCore: HackleCore {

    private let queue = DispatchQueue(label: "io.hackle.RecordingCore")
    private var count = 0

    var trackedCount: Int {
        queue.sync { count }
    }

    func experiment(experimentKey: Experiment.Key, user: HackleUser) throws -> Decision {
        fatalError("not used")
    }

    func experiments(user: HackleUser) throws -> [(Experiment, Decision)] {
        fatalError("not used")
    }

    func featureFlag(featureKey: Experiment.Key, user: HackleUser) throws -> FeatureFlagDecision {
        fatalError("not used")
    }

    func featureFlags(user: HackleUser) throws -> [(Experiment, FeatureFlagDecision)] {
        fatalError("not used")
    }

    func track(event: Event, user: HackleUser) {
        track(event: event, user: user, timestamp: Date())
    }

    func track(event: Event, user: HackleUser, timestamp: Date) {
        queue.async { self.count += 1 }
    }

    func remoteConfig(parameterKey: String, user: HackleUser, defaultValue: HackleValue) throws -> RemoteConfigDecision {
        fatalError("not used")
    }
}

private final class EmptyCohortFetcher: UserCohortFetcher {
    func fetch(user: User) async throws -> UserCohorts {
        UserCohorts.empty()
    }
}

private final class EmptyTargetEventFetcher: UserTargetEventFetcher {
    func fetch(user: User) async throws -> UserTargetEvents {
        UserTargetEvents.empty()
    }
}
