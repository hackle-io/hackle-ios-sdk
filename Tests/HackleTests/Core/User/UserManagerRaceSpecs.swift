import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


/// DefaultUserManager.context에 대한 data race 재현 스펙.
/// -enableThreadSanitizer YES 로 실행할 것.
class UserManagerRaceSpecs: QuickSpec {
    override class func spec() {

        it("DefaultUserManager: concurrent context write (background sync) vs read (toHackleUser/currentUser)") {
            let repository = MemoryKeyValueRepository()
            let cohortFetcher = MockUserCohortFetcher()
            let targetFetcher = MockUserTargetFetcher()
            let clock = FixedClock(date: Date(timeIntervalSince1970: 42))
            let deviceImpl = DeviceImpl(deviceId: "hackle_device_id")
            MainActor.assumeIsolated { deviceImpl.initialize() }
            let bundleInfo = BundleInfoImpl()
            let sut = DefaultUserManager(
                device: deviceImpl,
                bundleInfo: bundleInfo,
                repository: repository,
                cohortFetcher: cohortFetcher,
                targetFetcher: targetFetcher,
                clock: clock
            )
            every(cohortFetcher.fetchMock).answers { _, completion in
                completion(.success(UserCohorts()))
            }
            every(targetFetcher.fetchMock).answers { _, completion in
                completion(.success(UserTargetEvents()))
            }
            sut.initialize(user: User.builder().id("id").build())

            let writerIterations = 2_000
            let readerCount = 4
            let readerIterations = 15_000
            let group = DispatchGroup()

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<writerIterations {
                    let sem = DispatchSemaphore(value: 0)
                    sut.sync { sem.signal() }
                    sem.wait()
                }
            }

            for _ in 0..<readerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<readerIterations {
                        _ = sut.toHackleUser(user: User.builder().id("r-\(i)").build())
                        _ = sut.currentUser
                        _ = sut.resolve(user: nil, hackleAppContext: .default)
                    }
                }
            }

            group.wait()

            expect(sut.currentUser.id) == "id"
        }
    }
}
