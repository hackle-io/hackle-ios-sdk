import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


/// LocalUserManager.context에 대한 data race 재현 스펙.
/// -enableThreadSanitizer YES 로 실행할 것.
class UserManagerRaceSpecs: QuickSpec {
    override class func spec() {

        it("LocalUserManager: concurrent context write (background sync) vs read (toHackleUser/currentUser)") {
            let repository = MemoryKeyValueRepository()
            let cohortFetcher = MockUserCohortFetcher()
            let targetFetcher = MockUserTargetFetcher()
            let clock = FixedClock(date: Date(timeIntervalSince1970: 42))
            let deviceImpl = DeviceImpl(deviceId: "hackle_device_id")
            MainActor.assumeIsolated { deviceImpl.initialize() }
            let bundleInfo = BundleInfoImpl()
            let sut = LocalUserManager(
                device: deviceImpl,
                bundleInfo: bundleInfo,
                repository: UserRepository(repository: repository),
                cohortFetcher: cohortFetcher,
                targetFetcher: targetFetcher,
                clock: clock
            )
            every(cohortFetcher.fetchMock).answers { _ in UserCohorts() }
            every(targetFetcher.fetchMock).answers { _ in UserTargetEvents() }
            sut.initialize(user: User.builder().id("id").build())

            let writerIterations = 2_000
            let readerCount = 4
            let readerIterations = 15_000
            let group = DispatchGroup()

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<writerIterations {
                    let sem = DispatchSemaphore(value: 0)
                    Task {
                        try? await sut.sync()
                        sem.signal()
                    }
                    sem.wait()
                }
            }

            for _ in 0..<readerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<readerIterations {
                        _ = sut.hackleUser(user: User.builder().id("r-\(i)").build())
                        _ = sut.currentUser
                        _ = sut.hackleUser()
                    }
                }
            }

            group.wait()

            expect(sut.currentUser.id) == "id"
        }

        it("LocalUserManager: currentUser 는 onUserUpdated 발행이 끝난 뒤에 새 유저를 노출한다") {
            let cohortFetcher = MockUserCohortFetcher()
            let targetFetcher = MockUserTargetFetcher()
            every(cohortFetcher.fetchMock).answers { _ in UserCohorts() }
            every(targetFetcher.fetchMock).answers { _ in UserTargetEvents() }
            let sut = LocalUserManager(
                device: MockDevice(id: "device1", properties: [:]),
                bundleInfo: BundleInfoImpl(),
                repository: UserRepository(repository: MemoryKeyValueRepository()),
                cohortFetcher: cohortFetcher,
                targetFetcher: targetFetcher,
                clock: FixedClock(date: Date(timeIntervalSince1970: 42))
            )
            sut.initialize(user: User.builder().deviceId("device1").userId("old").build())

            assertCurrentUserIsPublishedAfterListeners(sut) { userManager in
                _ = userManager.setUserId(userId: "new")
            }
        }

        it("RemoteUserManager: currentUser 는 onUserUpdated 발행이 끝난 뒤에 새 유저를 노출한다") {
            let evaluationManager = WorkspaceEvaluationManager(
                fullEvaluator: ThrowingFullEvaluator(),
                partialEvaluator: PartialWorkspaceRemoteEvaluator(
                    client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: MockHttpClient())
                ),
                repository: FileWorkspaceEvaluationRepository(fileStorage: nil),
                cache: LruWorkspaceEvaluationCache(capacity: 10)
            )
            let sut = RemoteUserManager(
                clock: FixedClock(date: Date(timeIntervalSince1970: 42)),
                device: MockDevice(id: "device1", properties: [:]),
                bundleInfo: BundleInfoImpl(),
                repository: UserRepository(repository: MemoryKeyValueRepository()),
                evaluationManager: evaluationManager
            )
            sut.initialize(user: User.builder().deviceId("device1").userId("old").build())

            assertCurrentUserIsPublishedAfterListeners(sut) { userManager in
                _ = userManager.setUserId(userId: "new")
            }
        }
    }

    private static func assertCurrentUserIsPublishedAfterListeners<M: UserManager & Sendable>(
        _ sut: M,
        mutate: @escaping @Sendable (M) -> Void
    ) {
        let listener = BlockingUserListener()
        sut.addListener(listener: listener)

        DispatchQueue.global().async {
            mutate(sut)
        }
        expect(listener.entered.wait(timeout: .now() + 5)) == DispatchTimeoutResult.success

        let observed = AtomicReference<String?>(value: nil)
        let readerDone = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            observed.set(newValue: sut.currentUser.userId)
            readerDone.signal()
        }

        expect(readerDone.wait(timeout: .now() + 1)) == DispatchTimeoutResult.timedOut
        listener.release.signal()
        expect(readerDone.wait(timeout: .now() + 5)) == DispatchTimeoutResult.success
        expect(observed.get()) == "new"
    }
}

private final class BlockingUserListener: UserListener, @unchecked Sendable {
    let entered = DispatchSemaphore(value: 0)
    let release = DispatchSemaphore(value: 0)

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        entered.signal()
        release.wait()
    }

    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {
    }
}

private final class ThrowingFullEvaluator: FullWorkspaceRemoteEvaluator {
    init() {
        super.init(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: MockHttpClient()))
    }

    override func evaluate(request: FullWorkspaceEvaluateRequest) async throws -> FullWorkspaceEvaluateResponse {
        throw HackleError.error("stub")
    }
}
