//
//  ContextualEvaluatorSpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class ContextualEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var eventRecorder: EvaluationEventRecorder!

        beforeEach {
            eventRecorder = EvaluationEventRecorder(
                eventFactory: EvaluationEventFactory(clock: FixedClock(date: Date())),
                eventProcessor: MockUserEventProcessor()
            )
        }

        it("cleans up stack after successful evaluate") {
            let sut = ContextualEvaluatorStub(result: .success(StubEvaluateResponse()), eventRecorder: eventRecorder)
            let context = Evaluators.context()

            let response: StubEvaluateResponse = try sut.evaluate(request: StubEvaluateRequest(), context: context)

            expect(response.evaluation.entity.entityKey).to(equal(StubEvaluation().entity.entityKey))
            expect(context.stack.count).to(equal(0))
        }

        it("cleans up stack when doEvaluate throws") {
            let sut = ContextualEvaluatorStub(result: .failure, eventRecorder: eventRecorder)
            let context = Evaluators.context()

            expect {
                let _: StubEvaluateResponse = try sut.evaluate(request: StubEvaluateRequest(), context: context)
            }.to(throwError())

            expect(context.stack.count).to(equal(0))
        }

        it("throws on circular evaluation") {
            let sut = ContextualEvaluatorStub(result: .success(StubEvaluateResponse()), eventRecorder: eventRecorder)
            let context = Evaluators.context()

            let request = StubEvaluateRequest(entity: DefaultEntity(serviceType: .abTest, id: 1))
            context.add(request)

            expect {
                let _: StubEvaluateResponse = try sut.evaluate(request: request, context: context)
            }.to(throwError())
        }
    }

    enum StubResult {
        case success(StubEvaluateResponse)
        case failure
    }

    class ContextualEvaluatorStub: ContextualEvaluator {
        typealias Request = StubEvaluateRequest
        typealias Response = StubEvaluateResponse

        let eventRecorder: EvaluationEventRecorder
        private let result: StubResult

        init(result: StubResult, eventRecorder: EvaluationEventRecorder) {
            self.result = result
            self.eventRecorder = eventRecorder
        }

        func doEvaluate(request: StubEvaluateRequest, context: EvaluatorContext) throws -> StubEvaluateResponse {
            switch result {
            case .success(let response):
                return response
            case .failure:
                throw HackleError.error("doEvaluate failed")
            }
        }
    }
}
