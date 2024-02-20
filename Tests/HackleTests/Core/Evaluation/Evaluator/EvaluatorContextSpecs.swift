//
//  EvaluatorContextSpecs.swift
//  HackleTests
//
//  Created by Yong on 2024/02/01.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class EvaluatorContextSpecs: QuickSpec {
    override func spec() {

        it("stack") {
            let context = Evaluators.context()
            expect(context.stack.count).to(equal(0))

            let request1 = experimentRequest(experiment: experiment(id: 1))
            context.add(request1)
            let stack1 = context.stack
            expect(stack1.count).to(equal(1))

            let request2 = experimentRequest(experiment: experiment(id: 2))
            context.add(request2)
            let stack2 = context.stack
            expect(stack2.count).to(equal(2))

            context.remove(request2)
            expect(context.stack.count).to(equal(1))

            context.remove(request1)
            expect(context.stack.count).to(equal(0))

            expect(stack1.count).to(equal(1))
            expect(stack2.count).to(equal(2))
        }

        it("targetEvaluations") {

            let context = Evaluators.context()
            expect(context.targetEvaluations.count).to(equal(0))

            let experiment = experiment(id: 1)

            let evaluation1 = RemoteConfigEvaluation.ofDefault(request: remoteConfigRequest(), context: Evaluators.context(), reason: DecisionReason.DEFAULT_RULE, properties: PropertiesBuilder())
            context.add(evaluation1)
            let targetEvaluations1 = context.targetEvaluations
            expect(targetEvaluations1.count).to(equal(1))
            expect(context.get(experiment)).to(beNil())

            let evaluation2 = experimentEvaluation(experiment: experiment)
            context.add(evaluation2)
            let targetEvaluations2 = context.targetEvaluations
            expect(targetEvaluations1.count).to(equal(1))
            expect(targetEvaluations2.count).to(equal(2))
            expect(context.get(experiment)).to(beIdenticalTo(evaluation2))
        }

        it("properties") {
            let context = Evaluators.context()
            let p1 = context.properties
            expect(p1).to(be([:]))

            context.setProperty("a", 1)
            let p2 = context.properties

            expect(p1).to(be([:]))
            expect(p2["a"] as! Int).to(equal(1))
        }
    }
}
