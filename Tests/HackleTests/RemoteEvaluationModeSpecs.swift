import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

// NOTE: QuickSpec의 it 클로저는 `@MainActor () throws -> Void`(비동기 불가)라서,
// 두 번째 케이스의 실제 `await` 호출을 담으려면 AsyncSpec(`() async throws -> Void`)이 필요하다.
// 첫 번째 케이스(HackleApp.create 스모크)는 async 호출이 없지만, 기존 HackleAppSpec.swift의
// "create" 테스트가 @MainActor 컨텍스트(QuickSpec)에서 안정적으로 동작함이 확인된 패턴이므로,
// AsyncSpec의 비-MainActor Task 컨텍스트에서도 동일한 안전성을 보장하기 위해 MainActor.run으로 감싼다.
class RemoteEvaluationModeSpecs: AsyncSpec {
    override class func spec() {

        it("HackleApp.create가 REMOTE mode로 생성된다") {
            let config = HackleConfigBuilder()
                .mode(EvaluationMode.remote)
                .build()

            let app = await MainActor.run {
                HackleApp.create(sdkKey: "remote_smoke_sdk_key", config: config)
            }

            expect(app).toNot(beNil())
            expect(app.config.evaluationMode) == EvaluationMode.remote
        }

        it("REMOTE 그래프 end-to-end: setUser → evaluate 동기화 → 서버 평가 결과로 결정한다") {
            // HTTP 스텁: evaluate API가 FULL 응답 반환
            let httpClient = MockHttpClient()
            let file = Bundle(for: RemoteEvaluationModeSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let responseData = try! Data(contentsOf: URL(fileURLWithPath: file))
            every(httpClient.executeMock).answers { request, completion in
                completion(HttpResponse(
                    request: request,
                    data: responseData,
                    urlResponse: HTTPURLResponse(url: request.url, statusCode: 200, httpVersion: nil, headerFields: nil),
                    error: nil
                ))
            }

            // REMOTE 그래프 수동 조립 (create의 REMOTE 분기와 동일 구성)
            let evaluateClient = WorkspaceRemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            let evaluationManager = WorkspaceEvaluationManager(
                evaluateProcessor: WorkspaceEvaluateProcessor(
                    evaluatorFactory: WorkspaceRemoteEvaluatorFactory(evaluators: [
                        AllWorkspaceRemoteEvaluator(client: evaluateClient),
                        SpecificWorkspaceRemoteEvaluator(client: evaluateClient)
                    ])
                ),
                repository: FileWorkspaceEvaluationRepository(fileStorage: nil),
                cache: LruWorkspaceEvaluationCache(capacity: 10)
            )
            let userManager = RemoteUserManager(
                clock: SystemClock.shared,
                device: MockDevice(id: "device_id", properties: [:]),
                bundleInfo: BundleInfoImpl(),
                repository: UserRepository(repository: MemoryKeyValueRepository()),
                evaluationManager: evaluationManager
            )
            let evaluateProcessor = EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage.create(suiteName: "remote_mode_impression"),
                hiddenStorage: DefaultInAppMessageHiddenStorage.create(suiteName: "remote_mode_hidden")
            )
            let decisionProcessor = RemoteDecisionProcessor(workspaceFetcher: evaluationManager, evaluateProcessor: evaluateProcessor)

            // setUser가 evaluate 동기화를 수행해 캐시가 채워진다
            userManager.initialize(user: nil)
            await userManager.setUser(user: HackleUserBuilder().userId("user_1").build()).value

            // 서버 평가 결과(픽스처: experiment key 10 → variation B)로 결정
            let hackleUser = userManager.hackleUser()
            let decision = try decisionProcessor.experiment(experimentKey: 10, user: hackleUser)
            expect(decision.variation) == "B"
        }
    }
}
