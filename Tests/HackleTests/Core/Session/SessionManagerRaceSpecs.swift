import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


/// DefaultSessionManager.currentSession / lastEventTime 에 대한 data race 재현 스펙.
/// -enableThreadSanitizer YES 로 실행할 것.
class SessionManagerRaceSpecs: QuickSpec {
    override class func spec() {

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
