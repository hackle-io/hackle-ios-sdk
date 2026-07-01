//
//  EvaluateProcessorSpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class EvaluateProcessorSpecs: QuickSpec {
    override class func spec() {

        // 벌크 API record=false 회귀의 근거 케이스:
        // EvaluateProcessor.evaluate 는 request.record 가 true 일 때만 정확히 1회 record 를 트리거한다.

        it("records exactly once when request.record is true") {
            let evaluator = RecordingEvaluatorStub(response: StubEvaluateResponse())
            let sut = EvaluateProcessor(evaluatorFactory: EvaluatorFactory())

            let request = StubEvaluateRequest(record: true)
            let _: StubEvaluateResponse = try sut.evaluate(evaluator: evaluator, request: request)

            expect(evaluator.evaluateCount).to(equal(1))
            expect(evaluator.recordCount).to(equal(1))
        }

        it("does not record when request.record is false") {
            let evaluator = RecordingEvaluatorStub(response: StubEvaluateResponse())
            let sut = EvaluateProcessor(evaluatorFactory: EvaluatorFactory())

            let request = StubEvaluateRequest(record: false)
            let _: StubEvaluateResponse = try sut.evaluate(evaluator: evaluator, request: request)

            expect(evaluator.evaluateCount).to(equal(1))
            expect(evaluator.recordCount).to(equal(0))
        }
    }

    class RecordingEvaluatorStub: Evaluator {
        private let response: StubEvaluateResponse
        private(set) var evaluateCount = 0
        private(set) var recordCount = 0

        init(response: StubEvaluateResponse) {
            self.response = response
        }

        func evaluate<R: EvaluateResponse>(request: EvaluateRequest, context: EvaluatorContext) throws -> R {
            evaluateCount += 1
            return response as! R
        }

        func record(request: EvaluateRequest, response: EvaluateResponse) {
            recordCount += 1
        }
    }
}
