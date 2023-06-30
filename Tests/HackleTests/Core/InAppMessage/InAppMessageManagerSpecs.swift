//
//  InAppMessageManagerSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class InAppMessageManagerSpecs: QuickSpec {
    override func spec() {
        var determiner: MockInAppMessageDeterminer!
        var presenter: MockInAppMessagePresenter!
        var sut: InAppMessageManager!

        beforeEach {
            determiner = MockInAppMessageDeterminer()
            presenter = MockInAppMessagePresenter()
            sut = InAppMessageManager(determiner: determiner, presenter: presenter)
        }

        it("when cannot determine message then should not present") {
            // given
            every(determiner.determineOrNullMock).returns(nil)

            // when
            sut.onEvent(event: UserEvents.track("test"))

            // then
            verify(exactly: 0) {
                presenter.presentMock
            }
        }

        it("when exception occurs while determining message then should not present") {  // given
            every(determiner.determineOrNullMock).answers { _ in
                throw HackleError.error("fail")
            }

            // when
            sut.onEvent(event: UserEvents.track("test"))

            // then
            verify(exactly: 0) {
                presenter.presentMock
            }
        }

        it("when message is determined then present the message") {
            // given
            let context = InAppMessageContext(inAppMessage: .create(), message: InAppMessage.message(), properties: [:])
            every(determiner.determineOrNullMock).returns(context)

            // when
            sut.onEvent(event: UserEvents.track("test"))

            // then
            verify(exactly: 1) {
                presenter.presentMock
            }
            expect(presenter.presentMock.firstInvokation().arguments).to(beIdenticalTo(context))
        }
    }
}