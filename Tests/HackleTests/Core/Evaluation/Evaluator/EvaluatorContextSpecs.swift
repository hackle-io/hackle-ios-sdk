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
    override class func spec() {

        it("stack") {
            let context = Evaluators.context()
            expect(context.stack.count).to(equal(0))

            let request1 = StubEvaluateRequest(entity: DefaultEntity(serviceType: .abTest, id: 1))
            context.add(request1)
            let stack1 = context.stack
            expect(stack1.count).to(equal(1))
            expect(context.contains(request1)).to(beTrue())

            let request2 = StubEvaluateRequest(entity: DefaultEntity(serviceType: .abTest, id: 2))
            context.add(request2)
            let stack2 = context.stack
            expect(stack2.count).to(equal(2))

            context.remove(request2)
            expect(context.stack.count).to(equal(1))
            expect(context.contains(request2)).to(beFalse())

            context.remove(request1)
            expect(context.stack.count).to(equal(0))

            expect(stack1.count).to(equal(1))
            expect(stack2.count).to(equal(2))
        }

        it("references") {
            let context = Evaluators.context()
            expect(context.references.count).to(equal(0))

            let entity1 = DefaultEntity(serviceType: .abTest, id: 1)

            let evaluation1 = StubEvaluation(entity: DefaultEntity(serviceType: .remoteConfig, id: 42))
            context.add(evaluation1)
            let references1 = context.references
            expect(references1.count).to(equal(1))
            expect(context.get(entity1)).to(beNil())

            let evaluation2 = StubEvaluation(entity: entity1)
            context.add(evaluation2)
            let references2 = context.references
            expect(references1.count).to(equal(1))
            expect(references2.count).to(equal(2))
            expect(context.get(entity1)?.entity.entityKey).to(equal(entity1.entityKey))

            expect(context.get(DefaultEntity(serviceType: .abTest, id: 2))).to(beNil())
        }

        it("values (type store, array first-match)") {
            let context = Evaluators.context()

            expect(context.get(StubValueA.self)).to(beNil())

            let a = StubValueA(id: 1)
            context.set(a)
            expect(context.get(StubValueA.self)?.id).to(equal(1))
            expect(context.get(StubValueB.self)).to(beNil())

            let b = StubValueB(name: "b")
            context.set(b)
            expect(context.get(StubValueA.self)?.id).to(equal(1))
            expect(context.get(StubValueB.self)?.name).to(equal("b"))

            // first-match: 이후 추가된 동일 타입은 무시(배열 첫 매치 반환)
            context.set(StubValueA(id: 2))
            expect(context.get(StubValueA.self)?.id).to(equal(1))
        }

        it("properties") {
            let context = Evaluators.context()
            let p1 = context.properties
            expect(p1).to(beEmpty())

            context.setProperty("a", 1)
            let p2 = context.properties

            expect(p1).to(beEmpty())
            expect(p2["a"] as? Int).to(equal(1))
        }
    }

    struct StubValueA {
        let id: Int
    }

    struct StubValueB {
        let name: String
    }
}
