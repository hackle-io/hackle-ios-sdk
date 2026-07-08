//
//  LocalEvaluatorSpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class LocalEvaluatorSpecs: QuickSpec {
    override class func spec() {

        describe("ReferenceLocalEvaluator") {

            it("cache miss computes evaluation and adds it to context references") {
                let sut = ReferenceLocalEvaluatorStub()
                let context = Evaluators.context()
                let reference = DefaultEntity(serviceType: .abTest, id: 1)

                expect(context.references.count).to(equal(0))

                let evaluation = try sut.evaluate(
                    sourceRequest: StubLocalEvaluateRequest(),
                    context: context,
                    reference: reference
                )

                expect(evaluation.entity.entityKey).to(equal(reference.entityKey))
                expect(sut.doEvaluateCount).to(equal(1))
                expect(context.references.count).to(equal(1))
            }

            it("cache hit returns cached evaluation without recomputing") {
                let sut = ReferenceLocalEvaluatorStub()
                let context = Evaluators.context()
                let reference = DefaultEntity(serviceType: .abTest, id: 1)

                let cached = StubEvaluation(entity: reference)
                context.add(cached)
                expect(context.references.count).to(equal(1))

                let evaluation = try sut.evaluate(
                    sourceRequest: StubLocalEvaluateRequest(),
                    context: context,
                    reference: reference
                )

                expect(evaluation.entity.entityKey).to(equal(reference.entityKey))
                expect(sut.doEvaluateCount).to(equal(0))
                expect(context.references.count).to(equal(1))
            }
        }
    }

    struct StubLocalEvaluateRequest: LocalEvaluateRequest {
        var user: HackleUser = HackleUser.builder().build()
        var workspace: Workspace = MockWorkspace()
        var entity: Entity = DefaultEntity(serviceType: .abTest, id: 1)
        var record: Bool = false
    }

    class ReferenceLocalEvaluatorStub: ReferenceLocalEvaluator {
        typealias Reference = DefaultEntity
        typealias ReferenceEvaluation = StubEvaluation

        private(set) var doEvaluateCount = 0

        func cachedEvaluation(context: EvaluatorContext, reference: DefaultEntity) -> StubEvaluation? {
            context.get(reference) as? StubEvaluation
        }

        func doEvaluate(sourceRequest: LocalEvaluateRequest, context: EvaluatorContext, reference: DefaultEntity) throws -> StubEvaluation {
            doEvaluateCount += 1
            return StubEvaluation(entity: reference)
        }
    }
}
