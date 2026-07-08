//
//  DelegatingEvaluatorSpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DelegatingEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var eventRecorder: EvaluationEventRecorder!

        beforeEach {
            eventRecorder = EvaluationEventRecorder(
                eventFactory: EvaluationEventFactory(clock: FixedClock(date: Date())),
                eventProcessor: MockUserEventProcessor()
            )
        }

        describe("EvaluatorFactory") {

            it("get returns first-match evaluator") {
                let factory = EvaluatorFactory()

                let responseA = StubEvaluateResponse(evaluation: StubEvaluation(entity: DefaultEntity(serviceType: .abTest, id: 1)))
                let responseB = StubEvaluateResponse(evaluation: StubEvaluation(entity: DefaultEntity(serviceType: .featureFlag, id: 2)))

                let evaluatorA = ContextualEvaluatorStub<RequestA>(response: responseA, eventRecorder: eventRecorder)
                let evaluatorB = ContextualEvaluatorStub<RequestB>(response: responseB, eventRecorder: eventRecorder)

                factory.add(evaluatorA)
                factory.add(evaluatorB)

                let resolvedA = try factory.get(request: RequestA())
                expect(resolvedA.supports(request: RequestA())).to(beTrue())

                let resolvedB = try factory.get(request: RequestB())
                expect(resolvedB.supports(request: RequestB())).to(beTrue())
            }

            it("get throws when unsupported request") {
                let factory = EvaluatorFactory()
                factory.add(ContextualEvaluatorStub<RequestA>(response: StubEvaluateResponse(), eventRecorder: eventRecorder))

                expect(try factory.get(request: RequestB())).to(throwError())
            }
        }

        describe("DelegatingEvaluator") {

            it("evaluate delegates to matched evaluator") {
                let factory = EvaluatorFactory()

                let responseA = StubEvaluateResponse(evaluation: StubEvaluation(entity: DefaultEntity(serviceType: .abTest, id: 1)))
                let responseB = StubEvaluateResponse(evaluation: StubEvaluation(entity: DefaultEntity(serviceType: .featureFlag, id: 2)))
                factory.add(ContextualEvaluatorStub<RequestA>(response: responseA, eventRecorder: eventRecorder))
                factory.add(ContextualEvaluatorStub<RequestB>(response: responseB, eventRecorder: eventRecorder))

                let sut = DelegatingEvaluator(evaluatorFactory: factory)

                let actualA: StubEvaluateResponse = try sut.evaluate(request: RequestA(), context: Evaluators.context())
                expect(actualA.evaluation.entity.id).to(equal(1))

                let actualB: StubEvaluateResponse = try sut.evaluate(request: RequestB(), context: Evaluators.context())
                expect(actualB.evaluation.entity.id).to(equal(2))
            }

            it("evaluate throws when no evaluator supports request") {
                let sut = DelegatingEvaluator(evaluatorFactory: EvaluatorFactory())
                expect {
                    let _: StubEvaluateResponse = try sut.evaluate(request: RequestA(), context: Evaluators.context())
                }.to(throwError())
            }
        }
    }

    struct RequestA: EvaluateRequest {
        var user: HackleUser = HackleUser.builder().build()
        var workspace: Workspace = MockWorkspace()
        var entity: Entity = DefaultEntity(serviceType: .abTest, id: 1)
        var record: Bool = false
    }

    struct RequestB: EvaluateRequest {
        var user: HackleUser = HackleUser.builder().build()
        var workspace: Workspace = MockWorkspace()
        var entity: Entity = DefaultEntity(serviceType: .featureFlag, id: 2)
        var record: Bool = false
    }

    class ContextualEvaluatorStub<R: EvaluateRequest>: ContextualEvaluator {
        typealias Request = R
        typealias Response = StubEvaluateResponse

        let eventRecorder: EvaluationEventRecorder
        private let response: StubEvaluateResponse

        init(response: StubEvaluateResponse, eventRecorder: EvaluationEventRecorder) {
            self.response = response
            self.eventRecorder = eventRecorder
        }

        func doEvaluate(request: R, context: EvaluatorContext) throws -> StubEvaluateResponse {
            response
        }
    }
}
