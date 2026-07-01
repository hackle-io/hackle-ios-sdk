import Foundation
import Quick
import Nimble
@testable import Hackle

class EvaluateSkeletonSpecs: QuickSpec {
    override class func spec() {

        it("Evaluation exposes entity and result") {
            let entity = DefaultEntity(serviceType: .abTest, id: 42)
            let result = StubEvaluateResult(reason: DecisionReason.DEFAULT_RULE)
            let evaluation: Evaluation = StubEvaluation(entity: entity, result: result)

            expect(evaluation.entity.entityKey).to(equal(entity.entityKey))
            expect(evaluation.result.reason).to(equal(DecisionReason.DEFAULT_RULE))
        }

        it("EvaluateRequest exposes entity and record flag") {
            let entity = DefaultEntity(serviceType: .abTest, id: 1)
            let request: EvaluateRequest = StubEvaluateRequest(
                user: HackleUser.builder().build(),
                workspace: MockWorkspace(),
                entity: entity,
                record: false
            )
            expect(request.record).to(beFalse())
            expect(request.entity.entityKey).to(equal(entity.entityKey))
        }

        it("EvaluateResponse aggregates root evaluation and references") {
            let root = StubEvaluation(
                entity: DefaultEntity(serviceType: .abTest, id: 1),
                result: StubEvaluateResult(reason: DecisionReason.DEFAULT_RULE)
            )
            let reference = StubEvaluation(
                entity: DefaultEntity(serviceType: .abTest, id: 2),
                result: StubEvaluateResult(reason: DecisionReason.DEFAULT_RULE)
            )
            let response: EvaluateResponse = StubEvaluateResponse(
                user: HackleUser.builder().build(),
                workspace: MockWorkspace(),
                evaluation: root,
                references: [reference]
            )
            expect(response.evaluation.entity.id).to(equal(1))
            expect(response.references.count).to(equal(1))
        }
    }
}
