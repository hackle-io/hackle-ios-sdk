import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class RemoteInAppMessageTriggerDeterminerSpecs: QuickSpec {
    override class func spec() {

        func evaluationDto() -> WorkspaceEvaluationDto {
            let file = Bundle(for: RemoteInAppMessageTriggerDeterminerSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            return try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).full!
        }

        func user() -> HackleUser {
            HackleUser.builder().identifier(.id, "id_1").build()
        }

        func trackEvent(key: String) -> UserEvent {
            UserEvents.track(key, user: user())
        }

        var eventMatcher: MockInAppMessageTriggerEventMatcher!
        var cache: LruWorkspaceEvaluationCache!
        var workspaceManager: WorkspaceEvaluationManager!
        var sut: RemoteInAppMessageTriggerDeterminer!

        beforeEach {
            eventMatcher = MockInAppMessageTriggerEventMatcher()
            cache = LruWorkspaceEvaluationCache(capacity: 10)
            let evaluateClient = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: MockHttpClient())
            workspaceManager = WorkspaceEvaluationManager(
                fullEvaluator: FullWorkspaceRemoteEvaluator(client: evaluateClient),
                partialEvaluator: PartialWorkspaceRemoteEvaluator(client: evaluateClient),
                repository: FileWorkspaceEvaluationRepository(fileStorage: nil),
                cache: cache
            )
            let evaluateProcessor = EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: MockUserEventProcessor(),
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage.create(suiteName: "iam_remote_trigger_impression"),
                hiddenStorage: DefaultInAppMessageHiddenStorage.create(suiteName: "iam_remote_trigger_hidden")
            )
            sut = RemoteInAppMessageTriggerDeterminer(
                eventMatcher: eventMatcher,
                workspaceManager: workspaceManager,
                evaluateProcessor: evaluateProcessor
            )
        }

        it("workspace evaluation이 없으면 nil을 반환한다") {
            let trigger = try sut.determine(event: trackEvent(key: "view_home"))
            expect(trigger).to(beNil())
        }

        it("matcher가 매칭되고 eligibility가 eligible이면 trigger를 반환한다") {
            _ = cache.put(record: WorkspaceEvaluationContext.of(key: WorkspaceEvaluationContext.keyOf(user: user()), dto: evaluationDto(), fullEvaluatedAt: 0))
            // eventMatcher가 모든 IAM에 대해 true를 반환하도록 스텁 (기존 Mock의 등록 관례 사용)
            every(eventMatcher.matchesMock).returns(true)

            let trigger = try sut.determine(event: trackEvent(key: "view_home"))

            expect(trigger).toNot(beNil())
            expect(trigger?.inAppMessage.key) == 40
        }

        it("matcher가 매칭되지 않으면 nil을 반환한다") {
            _ = cache.put(record: WorkspaceEvaluationContext.of(key: WorkspaceEvaluationContext.keyOf(user: user()), dto: evaluationDto(), fullEvaluatedAt: 0))
            every(eventMatcher.matchesMock).returns(false)

            let trigger = try sut.determine(event: trackEvent(key: "view_home"))

            expect(trigger).to(beNil())
        }
    }
}
