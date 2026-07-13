import Foundation
import Quick
import Nimble
@testable import Hackle

private class RecordingSpecificEvaluator: WorkspaceRemoteEvaluator {
    var requests: [SpecificWorkspaceEvaluateRequest] = []
    var response: WorkspaceEvaluateResponse?

    func supports(scope: WorkspaceEvaluateScope) -> Bool {
        scope == .specific
    }

    func evaluate(request: WorkspaceEvaluateRequest) async throws -> WorkspaceEvaluateResponse {
        requests.append(request as! SpecificWorkspaceEvaluateRequest)
        guard let response = response else {
            throw HackleError.error("no stub response")
        }
        return response
    }
}

class InAppMessageDeliverRemoteEvaluatorSpecs: AsyncSpec {
    override class func spec() {

        func evaluationDto() -> WorkspaceEvaluationDto {
            let file = Bundle(for: InAppMessageDeliverRemoteEvaluatorSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            return try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).evaluation!
        }

        func user() -> HackleUser {
            HackleUser.builder().identifier(.id, "id_1").build()
        }

        func deliverRequest(inAppMessageKey: InAppMessage.Key) -> InAppMessageDeliverRequest {
            InAppMessageDeliverRequest(
                dispatchId: "dispatch_1",
                inAppMessageKey: inAppMessageKey,
                identifiers: ["$id": "id_1"],
                requestedAt: Date(),
                reason: "IN_APP_MESSAGE_TARGET",
                properties: [:],
                triggerEvent: Hackle.event(key: "trigger")
            )
        }

        var specificEvaluator: RecordingSpecificEvaluator!
        var evaluateProcessor: EvaluateProcessor!
        var workspaceManager: WorkspaceEvaluationManager!
        var cache: LruWorkspaceEvaluationCache!
        var sut: InAppMessageDeliverRemoteEvaluator!

        beforeEach {
            specificEvaluator = RecordingSpecificEvaluator()
            cache = LruWorkspaceEvaluationCache(capacity: 10)
            workspaceManager = WorkspaceEvaluationManager(
                evaluateProcessor: WorkspaceEvaluateProcessor(
                    evaluatorFactory: WorkspaceRemoteEvaluatorFactory(evaluators: [specificEvaluator])
                ),
                repository: FileWorkspaceEvaluationRepository(fileStorage: nil),
                cache: cache
            )
            evaluateProcessor = EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage.create(suiteName: "iam_remote_deliver_impression"),
                hiddenStorage: DefaultInAppMessageHiddenStorage.create(suiteName: "iam_remote_deliver_hidden")
            )
            sut = InAppMessageDeliverRemoteEvaluator(workspaceManager: workspaceManager, evaluateProcessor: evaluateProcessor)
        }

        func cacheWorkspace(dto: WorkspaceEvaluationDto) {
            _ = cache.put(record: WorkspaceEvaluationContext.of(key: WorkspaceEvaluationContext.keyOf(user: user()), dto: dto))
        }

        it("workspace가 없으면 WORKSPACE_NOT_FOUND ineligible이다") {
            let response = try await sut.evaluate(request: deliverRequest(inAppMessageKey: 40), user: user())
            expect(response.isEligible) == false
            expect(response.code) == InAppMessageDeliverResponse.Code.workspaceNotFound
        }

        it("in-app message가 없으면 IN_APP_MESSAGE_NOT_FOUND ineligible이다") {
            cacheWorkspace(dto: evaluationDto())
            let response = try await sut.evaluate(request: deliverRequest(inAppMessageKey: 999), user: user())
            expect(response.isEligible) == false
            expect(response.code) == InAppMessageDeliverResponse.Code.inAppMessageNotFound
        }

        context("atDeliverTime이 true인 경우 (픽스처 IAM 40)") {
            it("선평가(record:false)가 eligible이면 SPECIFIC 재평가로 fresh workspace를 받아 최종 평가한다") {
                cacheWorkspace(dto: evaluationDto())
                specificEvaluator.response = .of(status: .full, dto: evaluationDto())

                let response = try await sut.evaluate(request: deliverRequest(inAppMessageKey: 40), user: user())

                expect(specificEvaluator.requests.count) == 1
                expect(specificEvaluator.requests[0].targets.map { $0.id }) == [400]
                expect(response.isEligible) == true
                expect(response.evaluation).toNot(beNil())
            }

            it("SPECIFIC 재평가가 실패하면 에러가 전파된다") {
                cacheWorkspace(dto: evaluationDto())
                specificEvaluator.response = nil // throw 유도

                await expect {
                    try await sut.evaluate(request: deliverRequest(inAppMessageKey: 40), user: user())
                }.to(throwError())
            }
        }

        // atDeliverTime=false 경로: 픽스처를 복제해 evaluateContext.atDeliverTime=false로 바꾼 dto로 검증
        it("atDeliverTime이 false면 재평가 없이 기존 workspace로 평가한다") {
            let file = Bundle(for: InAppMessageDeliverRemoteEvaluatorSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            var json = try! String(contentsOf: URL(fileURLWithPath: file), encoding: .utf8)
            json = json.replacingOccurrences(of: "\"atDeliverTime\": true", with: "\"atDeliverTime\": false")
            let dto = try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: json.data(using: .utf8)!).evaluation!
            cacheWorkspace(dto: dto)

            let response = try await sut.evaluate(request: deliverRequest(inAppMessageKey: 40), user: user())

            expect(specificEvaluator.requests.count) == 0
            expect(response.isEligible) == true
        }
    }
}
