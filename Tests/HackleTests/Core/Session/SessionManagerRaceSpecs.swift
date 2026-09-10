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
            let sut = DefaultSessionManager(
                userManager: MockUserManager(),
                keyValueRepository: MemoryKeyValueRepository(),
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
                }
            }

            let started = listener.startedSessions
            let ended = listener.endedSessions
            expect(started.count) == 1 + threads * iterations
            expect(ended.count) == started.count - 1
            expect(Set(ended.map { $0.id }).count) == ended.count
            expect(Set(ended.map { $0.id })) == Set(started.dropLast().map { $0.id })
            expect(started.last) == sut.currentSession
        }
    }
}

private class RaceSessionListener: SessionListener {

    private let lock = NSLock()
    private var started = [Session]()
    private var ended = [Session]()

    var startedSessions: [Session] { sync { started } }
    var endedSessions: [Session] { sync { ended } }

    func onSessionStarted(session: Session, user: User, timestamp: Date) {
        sync { started.append(session) }
    }

    func onSessionEnded(session: Session, user: User, timestamp: Date) {
        sync { ended.append(session) }
    }

    private func sync<T>(_ block: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return block()
    }
}
