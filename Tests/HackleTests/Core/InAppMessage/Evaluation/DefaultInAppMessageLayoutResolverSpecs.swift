import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageLayoutResolverSpecs: QuickSpec {
    override func spec() {

        it("resolve") {
            // given
            let core = MockHackleCore()
            let layoutEvalautor = InAppMessageLayoutEvaluator(
                experimentEvaluator: InAppMessageExperimentEvaluator(
                    evaluator: MockEvaluator()
                ),
                selector: InAppMessageLayoutSelector(),
                eventRecorder: MockEvaluationEventRecorder()
            )
            let sut = DefaultInAppMessageLayoutResolver(
                core: core,
                layoutEvaluator: layoutEvalautor
            )

            let evaluation = InAppMessage.layoutEvaluation()
            every(core.inAppMessageMock).returns(evaluation)

            let workspace = WorkspaceEntity.create()
            let inAppMessage = InAppMessage.create()
            let user = HackleUser.of(userId: "test")

            // when
            let actual = try sut.resolve(workspace: workspace, inAppMessage: inAppMessage, user: user)

            // then
            expect(actual).to(beIdenticalTo(evaluation))
            expect(core.inAppMessageMock.firstInvokation().arguments.2).to(beIdenticalTo(layoutEvalautor))
        }
    }
}
