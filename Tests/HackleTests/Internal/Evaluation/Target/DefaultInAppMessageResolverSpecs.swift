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
        var sut: DefaultInAppMessageResolver!

        beforeEach {
            sut = DefaultInAppMessageResolver()
        }

        it("resolve") {
            // given
            let message = InAppMessage.message(lang: "ko")
            let inAppMessage = InAppMessage.create(
                messageContext: InAppMessage.context(
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
                messageContext: InAppMessage.context(
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