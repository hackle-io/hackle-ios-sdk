import Foundation
import Quick
import Nimble
@testable import Hackle

private class StubWorkspaceRemoteEvaluator: WorkspaceRemoteEvaluator {
    let scope: WorkspaceEvaluateScope
    var responses: [Result<WorkspaceEvaluateResponse, Error>] = []
    var receivedRequests: [WorkspaceEvaluateRequest] = []

    init(scope: WorkspaceEvaluateScope) {
        self.scope = scope
    }

    func supports(scope: WorkspaceEvaluateScope) -> Bool {
        self.scope == scope
    }

    func evaluate(request: WorkspaceEvaluateRequest) async throws -> WorkspaceEvaluateResponse {
        receivedRequests.append(request)
        return try responses.removeFirst().get()
    }
}

class WorkspaceEvaluationManagerSpecs: AsyncSpec {
    override class func spec() {

        func evaluationDto() -> WorkspaceEvaluationDto {
            let file = Bundle(for: WorkspaceEvaluationManagerSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            return try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).evaluation!
        }

        func user(id: String) -> HackleUser {
            HackleUser.builder().identifier(.id, id).build()
        }

        var allEvaluator: StubWorkspaceRemoteEvaluator!
        var specificEvaluator: StubWorkspaceRemoteEvaluator!
        var repository: FileWorkspaceEvaluationRepository!
        var fileStorage: MockFileStorage!
        var cache: LruWorkspaceEvaluationCache!
        var sut: WorkspaceEvaluationManager!

        beforeEach {
            allEvaluator = StubWorkspaceRemoteEvaluator(scope: .all)
            specificEvaluator = StubWorkspaceRemoteEvaluator(scope: .specific)
            fileStorage = MockFileStorage()
            repository = FileWorkspaceEvaluationRepository(fileStorage: fileStorage)
            cache = LruWorkspaceEvaluationCache(capacity: 10)
            sut = WorkspaceEvaluationManager(
                evaluateProcessor: WorkspaceEvaluateProcessor(
                    evaluatorFactory: WorkspaceRemoteEvaluatorFactory(evaluators: [allEvaluator, specificEvaluator])
                ),
                repository: repository,
                cache: cache
            )
        }

        describe("initialize") {
            it("파일에 저장된 record를 캐시로 복원한다") {
                let record = WorkspaceEvaluationContext.of(
                    key: WorkspaceEvaluationContext.keyOf(user: user(id: "id_1")),
                    dto: evaluationDto()
                )
                repository.set(records: [record])

                sut.initialize()

                expect(sut.workspace(user: user(id: "id_1"))).toNot(beNil())
                expect(sut.metadata()?.id) == 1
            }

            it("저장된 것이 없으면 빈 상태다") {
                sut.initialize()
                expect(sut.workspace(user: user(id: "id_1"))).to(beNil())
                expect(sut.metadata()).to(beNil())
            }
        }

        describe("sync") {
            it("FULL 응답이면 캐시에 저장하고 전체 스냅샷을 파일에 저장한다") {
                allEvaluator.responses = [.success(.of(status: .full, dto: evaluationDto()))]

                let context = RemoteEvaluateContext.of(user: user(id: "id_1"))
                await sut.sync(context: context)

                let workspace: WorkspaceEvaluation? = sut.workspace(user: user(id: "id_1"))
                expect(workspace?.metadata.id) == 1
                expect(repository.get().count) == 1 // 파일 저장 확인
            }

            it("record가 있으면 AllWorkspaceEvaluateRequest에 record를 실어 보낸다") {
                allEvaluator.responses = [
                    .success(.of(status: .full, dto: evaluationDto())),
                    .success(.notModified())
                ]
                let context = RemoteEvaluateContext.of(user: user(id: "id_1"))

                await sut.sync(context: context)
                await sut.sync(context: context)

                let first = allEvaluator.receivedRequests[0] as! AllWorkspaceEvaluateRequest
                let second = allEvaluator.receivedRequests[1] as! AllWorkspaceEvaluateRequest
                expect(first.record).to(beNil())
                expect(second.record).toNot(beNil())
            }

            it("NOT_MODIFIED면 기존 record를 유지한다") {
                allEvaluator.responses = [
                    .success(.of(status: .full, dto: evaluationDto())),
                    .success(.notModified())
                ]
                let context = RemoteEvaluateContext.of(user: user(id: "id_1"))

                await sut.sync(context: context)
                await sut.sync(context: context)

                expect(sut.workspace(user: user(id: "id_1"))).toNot(beNil())
            }

            it("실패해도 throw하지 않고 로그만 남긴다 (기존 상태 유지)") {
                allEvaluator.responses = [.failure(HackleError.error("http fail"))]

                await sut.sync(context: RemoteEvaluateContext.of(user: user(id: "id_1")))

                expect(sut.workspace(user: user(id: "id_1"))).to(beNil())
            }
        }

        describe("workspace(user:)") {
            it("키가 일치하는 유저만 workspace를 얻는다 (SESSION 제외 규칙 반영)") {
                allEvaluator.responses = [.success(.of(status: .full, dto: evaluationDto()))]
                let syncUser = HackleUser.builder()
                    .identifier(.id, "id_1")
                    .identifier(.session, "session_1")
                    .build()
                await sut.sync(context: RemoteEvaluateContext.of(user: syncUser))

                let sameUserNewSession = HackleUser.builder()
                    .identifier(.id, "id_1")
                    .identifier(.session, "session_2")
                    .build()
                let otherUser = user(id: "id_2")

                expect(sut.workspace(user: sameUserNewSession)).toNot(beNil())
                expect(sut.workspace(user: otherUser)).to(beNil())
            }
        }

        describe("evaluate (SPECIFIC)") {
            it("응답 evaluation으로 일회성 WorkspaceEvaluation을 만들고 캐시·파일에는 저장하지 않는다") {
                specificEvaluator.responses = [.success(.of(status: .full, dto: evaluationDto()))]

                let result = try await sut.evaluate(
                    context: RemoteEvaluateContext.of(user: user(id: "id_1")),
                    entities: [DefaultEntity(serviceType: .inAppMessage, id: 400)]
                )

                expect(result.metadata.id) == 1
                expect(sut.workspace(user: user(id: "id_1"))).to(beNil()) // 캐시 미저장
                expect(repository.get()).to(beEmpty()) // 파일 미저장
                let request = specificEvaluator.receivedRequests[0] as! SpecificWorkspaceEvaluateRequest
                expect(request.targets.count) == 1
            }

            it("응답 evaluation이 없으면 throw한다") {
                specificEvaluator.responses = [.success(.notModified())]

                await expect {
                    try await sut.evaluate(context: RemoteEvaluateContext.of(user: user(id: "id_1")), entities: [])
                }.to(throwError())
            }
        }

        describe("scope에 맞는 evaluator가 없는 경우") {
            it("sync는 factory throw도 삼키고 기존 상태를 유지한다") {
                let noEvaluatorSut = WorkspaceEvaluationManager(
                    evaluateProcessor: WorkspaceEvaluateProcessor(
                        evaluatorFactory: WorkspaceRemoteEvaluatorFactory(evaluators: [])
                    ),
                    repository: FileWorkspaceEvaluationRepository(fileStorage: MockFileStorage()),
                    cache: LruWorkspaceEvaluationCache(capacity: 10)
                )

                await noEvaluatorSut.sync(context: RemoteEvaluateContext.of(user: user(id: "id_1")))

                expect(noEvaluatorSut.workspace(user: user(id: "id_1"))).to(beNil())
            }

            it("evaluate는 factory throw를 그대로 전파한다") {
                let noEvaluatorSut = WorkspaceEvaluationManager(
                    evaluateProcessor: WorkspaceEvaluateProcessor(
                        evaluatorFactory: WorkspaceRemoteEvaluatorFactory(evaluators: [])
                    ),
                    repository: FileWorkspaceEvaluationRepository(fileStorage: MockFileStorage()),
                    cache: LruWorkspaceEvaluationCache(capacity: 10)
                )

                await expect {
                    try await noEvaluatorSut.evaluate(context: RemoteEvaluateContext.of(user: user(id: "id_1")), entities: [])
                }.to(throwError())
            }
        }
    }
}
