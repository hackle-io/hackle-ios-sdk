import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

// FullWorkspaceRemoteEvaluator를 상속해 요청을 기록한다. 실제 네트워크는 타지 않으며,
// evaluate는 항상 throw하지만 Manager.sync가 에러를 삼키므로 sync 흐름은 정상 완료된다.
private class RecordingFullEvaluator: FullWorkspaceRemoteEvaluator {
    var requests: [FullWorkspaceEvaluateRequest] = []

    init() {
        super.init(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: MockHttpClient()))
    }

    override func evaluate(request: FullWorkspaceEvaluateRequest) async throws -> FullWorkspaceEvaluateResponse {
        requests.append(request)
        throw HackleError.error("stub")
    }
}

private class RecordingUserListener: UserListener {
    var updated: [(old: User, new: User)] = []
    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        updated.append((oldUser, newUser))
    }
    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {
    }
}

// RemoteUserManager는 REMOTE 모드의 UserManager 구현체다. mutator는 async가 아니라 `-> Task<Void, Never>`이며
// (mutation은 lock 아래 동기적으로 끝나고 네트워크 sync만 Task로 미룬다), 그래서 아래 테스트는
// `await sut.setUser(...).value`로 sync 완료를 기다린다.
class RemoteUserManagerSpecs: AsyncSpec {
    override class func spec() {

        var allEvaluator: RecordingFullEvaluator!
        var repository: UserRepository!
        var listener: RecordingUserListener!
        var device: MockDevice!
        var sut: RemoteUserManager!

        beforeEach {
            allEvaluator = RecordingFullEvaluator()
            repository = UserRepository(repository: MemoryKeyValueRepository())
            listener = RecordingUserListener()
            device = MockDevice(id: "hackle_device_id", properties: ["platform": "iOS"])
            let evaluationManager = WorkspaceEvaluationManager(
                fullEvaluator: allEvaluator,
                partialEvaluator: PartialWorkspaceRemoteEvaluator(
                    client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: MockHttpClient())
                ),
                repository: FileWorkspaceEvaluationRepository(fileStorage: nil),
                cache: LruWorkspaceEvaluationCache(capacity: 10)
            )
            sut = RemoteUserManager(
                clock: SystemClock.shared,
                device: device,
                bundleInfo: BundleInfoImpl(),
                repository: repository,
                evaluationManager: evaluationManager
            )
            sut.addListener(listener: listener)
        }

        describe("initialize") {
            it("전달된 user로 초기화하고 initSyncContext를 세팅한다 (sync()가 이를 소비)") {
                sut.initialize(user: HackleUserBuilder().userId("user_1").property("age", 30).build())

                expect(sut.currentUser.userId) == "user_1"
                expect(sut.currentUser.properties.isEmpty) == true // sanitize

                // 첫 sync()는 initSyncContext($set operations 포함)를 소비
                try await sut.sync()
                expect(allEvaluator.requests.count) == 1
                let body = allEvaluator.requests[0].context.operations
                expect(body.count) == 1 // $set(age)

                // 두 번째 sync()는 current context·empty operations
                try await sut.sync()
                expect(allEvaluator.requests.count) == 2
                expect(allEvaluator.requests[1].context.operations.count) == 0
            }

            it("user가 없으면 저장된 유저, 그것도 없으면 deviceId 기반 기본 유저로 초기화한다") {
                sut.initialize(user: nil)
                expect(sut.currentUser.deviceId) == "hackle_device_id"
            }
        }

        describe("hackleUser") {
            it("cohorts/targetEvents 없이 식별자·프로퍼티만 부착한다") {
                sut.initialize(user: HackleUserBuilder().userId("user_1").build())

                let hackleUser = sut.hackleUser()

                expect(hackleUser.identifiers["$userId"]) == "user_1"
                expect(hackleUser.identifiers["$hackleDeviceId"]) == "hackle_device_id"
                expect(hackleUser.cohorts.isEmpty) == true
                expect(hackleUser.targetEvents.isEmpty) == true
                expect(hackleUser.hackleProperties["platform"] as? String) == "iOS"
            }
        }

        describe("syncIfNeeded 3조건") {
            beforeEach {
                sut.initialize(user: HackleUserBuilder().userId("user_1").build())
            }

            it("setUser로 식별자(evaluationKey)가 바뀌면 sync하고 onUserUpdated를 통지한다") {
                await sut.setUser(user: HackleUserBuilder().userId("user_2").build()).value

                expect(allEvaluator.requests.count) == 1
                expect(listener.updated.count) == 1
                expect(listener.updated[0].new.userId) == "user_2"
            }

            it("operations가 있으면 식별자가 같아도 sync한다 (setUser: $set properties)") {
                await sut.setUser(user: HackleUserBuilder().userId("user_1").property("age", 30).build()).value

                // 식별자 동일 → onUserUpdated 없음, operations($set) 때문에 sync는 발생
                expect(listener.updated.count) == 0
                expect(allEvaluator.requests.count) == 1
            }

            it("식별자도 같고 operations도 없으면 sync하지 않는다 (setDeviceId 동일값)") {
                let deviceId = sut.currentUser.deviceId!
                await sut.setDeviceId(deviceId: deviceId).value

                expect(allEvaluator.requests.count) == 0
                expect(listener.updated.count) == 0
            }

            it("updateProperties는 로컬에 저장하지 않고 operations만 서버로 보낸다") {
                let operations = PropertyOperations.builder().set("grade", "GOLD").build()
                await sut.updateProperties(operations: operations).value

                expect(allEvaluator.requests.count) == 1
                expect(sut.currentUser.properties.isEmpty) == true // 로컬 미저장
            }

            it("updateProperties에 operations가 없으면 아무것도 하지 않는다") {
                await sut.updateProperties(operations: PropertyOperations.empty()).value
                expect(allEvaluator.requests.count) == 0
            }

            it("resetUser는 clearAll operations로 sync한다") {
                await sut.setUser(user: HackleUserBuilder().userId("user_2").build()).value
                allEvaluator.requests = []

                await sut.resetUser().value

                expect(allEvaluator.requests.count) == 1
                expect(sut.currentUser.userId).to(beNil())
            }
        }

        // 동기 프리픽스 회귀 가드: mutator는 mutation을 반환 전에 recursiveLock 아래 동기적으로 끝내므로,
        // 반환된 Task를 await하기 전에도 currentUser는 이미 변경을 반영해야 한다.
        // updateProperties는 로컬 상태를 바꾸지 않으므로 가드 대상이 아니다.
        describe("동기 프리픽스 (mutation before Task return)") {
            beforeEach {
                sut.initialize(user: HackleUserBuilder().userId("user_1").build())
            }

            it("setUser 반환 즉시 currentUser가 갱신된다 (Task await 이전)") {
                let task = sut.setUser(user: HackleUserBuilder().userId("user_2").build())

                expect(sut.currentUser.userId) == "user_2"

                await task.value
            }

            it("setUserId 반환 즉시 currentUser가 갱신된다 (Task await 이전)") {
                let task = sut.setUserId(userId: "user_2")

                expect(sut.currentUser.userId) == "user_2"

                await task.value
            }

            it("setDeviceId 반환 즉시 currentUser가 갱신된다 (Task await 이전)") {
                let task = sut.setDeviceId(deviceId: "device_2")

                expect(sut.currentUser.deviceId) == "device_2"

                await task.value
            }

            it("resetUser 반환 즉시 currentUser가 기본 유저로 갱신된다 (Task await 이전)") {
                let task = sut.resetUser()

                expect(sut.currentUser.userId).to(beNil())

                await task.value
            }
        }

        describe("lifecycle") {
            it("onBackground에서 currentUser를 저장한다") {
                sut.initialize(user: HackleUserBuilder().userId("user_1").build())

                sut.onBackground(nil, timestamp: Date())

                expect(repository.get()?.userId) == "user_1"
            }
        }
    }
}
