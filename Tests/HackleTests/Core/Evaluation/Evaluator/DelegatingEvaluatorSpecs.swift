//
//  DelegatingEvaluatorSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DelegatingEvaluatorSpecs: QuickSpec {
    override func spec() {

        it("evaluate") {
            let sut = DelegatingEvaluator()

            let r1 = experimentRequest()
            let e1 = experimentEvaluation()

            expect {
                let _: ExperimentEvaluation = try sut.evaluate(request: r1, context: Evaluators.context())
            }
                .to(throwError())

            let evaluator = ContextualEvaluatorStub(evaluation: e1)
            sut.add(evaluator)


            let actual: ExperimentEvaluation = try sut.evaluate(request: r1, context: Evaluators.context())
            expect(actual).to(beIdenticalTo(e1))

            expect {
                let _: ExperimentEvaluation = try sut.evaluate(request: remoteConfigRequest(), context: Evaluators.context())
            }
                .to(throwError())
        }
    }


    class ContextualEvaluatorStub: ContextualEvaluator {
        typealias Request = ExperimentRequest
        typealias Evaluation = ExperimentEvaluation

        private let evaluation: Evaluation

        init(evaluation: Evaluation) {
            self.evaluation = evaluation
        }

        func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {
            evaluation
        }
    }
}