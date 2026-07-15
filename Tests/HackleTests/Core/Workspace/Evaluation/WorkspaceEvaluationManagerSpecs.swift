import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

private class RecordingFullEvaluator: FullWorkspaceRemoteEvaluator {
    var requests: [FullWorkspaceEvaluateRequest] = []
    var responder: ((FullWorkspaceEvaluateRequest) throws -> FullWorkspaceEvaluateResponse)?

    init() {
        super.init(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: MockHttpClient()))
    }

    override func evaluate(request: FullWorkspaceEvaluateRequest) async throws -> FullWorkspaceEvaluateResponse {
        requests.append(request)
        guard let responder = responder else {
            throw HackleError.error("no responder")
        }
        return try responder(request)
    }
}

private class RecordingPartialEvaluator: PartialWorkspaceRemoteEvaluator {
    var requests: [PartialWorkspaceEvaluateRequest] = []
    var responder: ((PartialWorkspaceEvaluateRequest) throws -> PartialWorkspaceEvaluateResponse)?

    init() {
        super.init(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: MockHttpClient()))
    }

    override func evaluate(request: PartialWorkspaceEvaluateRequest) async throws -> PartialWorkspaceEvaluateResponse {
        requests.append(request)
        guard let responder = responder else {
            throw HackleError.error("no responder")
        }
        return try responder(request)
    }
}

class WorkspaceEvaluationManagerSpecs: AsyncSpec {
    override class func spec() {

        func evaluationDto() -> WorkspaceEvaluationDto {
            let file = Bundle(for: WorkspaceEvaluationManagerSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            return try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).full!
        }

        func user(id: String) -> HackleUser {
            HackleUser.builder().identifier(.id, id).build()
        }

        // FULL 응답을 모사: request.context.key로 새 context를 만들어 반환
        func fullResponse(request: FullWorkspaceEvaluateRequest) -> FullWorkspaceEvaluateResponse {
            let dto = evaluationDto()
            let context = WorkspaceEvaluationContext.of(key: request.context.key, dto: dto, fullEvaluatedAt: dto.metadata.evaluatedAt)
            return FullWorkspaceEvaluateResponse(context: context)
        }

        var fullEvaluator: RecordingFullEvaluator!
        var partialEvaluator: RecordingPartialEvaluator!
        var repository: FileWorkspaceEvaluationRepository!
        var fileStorage: MockFileStorage!
        var cache: LruWorkspaceEvaluationCache!
        var sut: WorkspaceEvaluationManager!

        beforeEach {
            fullEvaluator = RecordingFullEvaluator()
            partialEvaluator = RecordingPartialEvaluator()
            fileStorage = MockFileStorage()
            repository = FileWorkspaceEvaluationRepository(fileStorage: fileStorage)
            cache = LruWorkspaceEvaluationCache(capacity: 10)
            sut = WorkspaceEvaluationManager(
                fullEvaluator: fullEvaluator,
                partialEvaluator: partialEvaluator,
                repository: repository,
                cache: cache
            )
        }

        describe("initialize") {
            it("파일에 저장된 record를 캐시로 복원한다") {
                let record = WorkspaceEvaluationContext.of(
                    key: WorkspaceEvaluationContext.keyOf(user: user(id: "id_1")),
                    dto: evaluationDto(),
                    fullEvaluatedAt: 0
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
                fullEvaluator.responder = { request in fullResponse(request: request) }

                let context = RemoteEvaluateContext.of(user: user(id: "id_1"))
                await sut.sync(context: context)

                let workspace: WorkspaceEvaluation? = sut.workspace(user: user(id: "id_1"))
                expect(workspace?.metadata.id) == 1
                expect(repository.get().count) == 1 // 파일 저장 확인
            }

            it("첫 sync는 base 없이, 캐시가 채워진 뒤 두 번째 sync는 base를 실어 보낸다") {
                fullEvaluator.responder = { request in
                    if let base = request.base {
                        return FullWorkspaceEvaluateResponse(context: base) // 204(NOT_MODIFIED) 모사
                    }
                    return fullResponse(request: request)
                }
                let context = RemoteEvaluateContext.of(user: user(id: "id_1"))

                await sut.sync(context: context)
                await sut.sync(context: context)

                expect(fullEvaluator.requests[0].base).to(beNil())
                expect(fullEvaluator.requests[1].base).toNot(beNil())
            }

            it("base를 그대로 반환(NOT_MODIFIED)해도 기존 record를 유지한다") {
                fullEvaluator.responder = { request in
                    if let base = request.base {
                        return FullWorkspaceEvaluateResponse(context: base)
                    }
                    return fullResponse(request: request)
                }
                let context = RemoteEvaluateContext.of(user: user(id: "id_1"))

                await sut.sync(context: context)
                await sut.sync(context: context)

                expect(sut.workspace(user: user(id: "id_1"))).toNot(beNil())
            }

            it("실패해도 throw하지 않고 로그만 남긴다 (기존 상태 유지)") {
                fullEvaluator.responder = { _ in throw HackleError.error("http fail") }

                await sut.sync(context: RemoteEvaluateContext.of(user: user(id: "id_1")))

                expect(sut.workspace(user: user(id: "id_1"))).to(beNil())
            }
        }

        describe("workspace(user:)") {
            it("키가 일치하는 유저만 workspace를 얻는다 (SESSION 제외 규칙 반영)") {
                fullEvaluator.responder = { request in fullResponse(request: request) }
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

        describe("evaluate (partial)") {
            it("응답 evaluation으로 일회성 WorkspaceEvaluation을 만들고 캐시·파일에는 저장하지 않는다") {
                partialEvaluator.responder = { _ in
                    PartialWorkspaceEvaluateResponse(evaluation: DefaultWorkspaceEvaluation.from(dto: evaluationDto(), fullEvaluatedAt: 0))
                }

                let result = try await sut.evaluate(
                    context: RemoteEvaluateContext.of(user: user(id: "id_1")),
                    entities: [DefaultEntity(serviceType: .inAppMessage, id: 400)]
                )

                expect(result.metadata.id) == 1
                expect(sut.workspace(user: user(id: "id_1"))).to(beNil()) // 캐시 미저장
                expect(repository.get()).to(beEmpty()) // 파일 미저장
                expect(partialEvaluator.requests[0].entities.count) == 1
            }

            it("partialEvaluator가 실패하면 throw한다") {
                partialEvaluator.responder = { _ in throw HackleError.error("partial fail") }

                await expect {
                    try await sut.evaluate(context: RemoteEvaluateContext.of(user: user(id: "id_1")), entities: [])
                }.to(throwError())
            }
        }
    }
}
