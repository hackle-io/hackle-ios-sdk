//
//  DefaultInAppMessageResolverSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultInAppMessageResolverSpecs: QuickSpec {


    override func spec() {
        var evaluator: MockEvaluator!
        var sut: DefaultInAppMessageResolver!

        beforeEach {
            evaluator = MockEvaluator()
            sut = DefaultInAppMessageResolver(evaluator: evaluator)
        }

        describe("experiment") {
            it("when cannot get experiment then throws error") {
                let messageContext = InAppMessage.messageContext(experimentContext: InAppMessage.ExperimentContext(key: 42))
                let inAppMessage = InAppMessage.create(messageContext: messageContext)
                let request = InAppMessage.request(inAppMessage: inAppMessage)

                expect(try sut.resolve(request: request, context: Evaluators.context())).to(throwError())
            }

            it("resolved by variation") {
                // given
                let message = InAppMessage.message(variationKey: "B")
                let messageContext = InAppMessage.messageContext(
                    experimentContext: InAppMessage.ExperimentContext(key: 42),
                    messages: [message]
                )
                let inAppMessage = InAppMessage.create(messageContext: messageContext)

                let experiment = experiment(id: 5, key: 42)
                let workspace = WorkspaceEntity.create(experiments: [experiment])

                let request = InAppMessage.request(workspace: workspace, inAppMessage: inAppMessage)
                let evaluation = experimentEvaluation(
                    reason: DecisionReason.TRAFFIC_ALLOCATED,
                    targetEvaluations: [],
                    experiment: experiment,
                    variationId: 320,
                    variationKey: "B"
                )
                evaluator.returns = evaluation
                let context = Evaluators.context()

                // when
                let actual = try sut.resolve(request: request, context: context)

                // then
                expect(actual).to(be(message))
                expect(context.get(experiment)).to(be(evaluation))
                expect(context.properties["experiment_id"]).to(be(5))
                expect(context.properties["experiment_key"]).to(be(42))
                expect(context.properties["variation_id"]).to(be(320))
                expect(context.properties["variation_key"]).to(be("B"))
                expect(context.properties["experiment_decision_reason"] as? String).to(equal("TRAFFIC_ALLOCATED"))
            }
        }

        it("resolve") {
            // given
            let message = InAppMessage.message(lang: "ko")
            let inAppMessage = InAppMessage.create(
                messageContext: InAppMessage.messageContext(
                    defaultLang: "ko",
                    messages: [message]
                )
            )
            let request = InAppMessage.request(inAppMessage: inAppMessage)

            // when
            let actual = try sut.resolve(request: request, context: Evaluators.context())

            // then
            expect(actual).to(beIdenticalTo(message))
        }

        it("cannot resolve") {
            let message = InAppMessage.message(lang: "ko")
            let inAppMessage = InAppMessage.create(
                messageContext: InAppMessage.messageContext(
                    defaultLang: "en",
                    messages: [message]
                )
            )
            let request = InAppMessage.request(inAppMessage: inAppMessage)

            expect(try sut.resolve(request: request, context: Evaluators.context()))
                .to(throwError())
        }
    }
}