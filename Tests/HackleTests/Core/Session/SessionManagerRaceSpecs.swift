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
