import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageActionHandlerSpecs: QuickSpec {
    override func spec() {

        describe("InAppMessageCloseActionHandler") {
            var sut: InAppMessageCloseActionHandler!

            beforeEach {
                sut = InAppMessageCloseActionHandler()
            }

            it("supports") {
                expect(sut.supports(action: InAppMessage.action(type: .close))) == true
                expect(sut.supports(action: InAppMessage.action(type: .webLink))) == false
                expect(sut.supports(action: InAppMessage.action(type: .hidden))) == false
            }

            it("handle close") {
                let view = MockInAppMessageView(presented: true)
                sut.handle(view: view, action: InAppMessage.action(type: .close))
                expect(view.presented) == false
            }
        }

        describe("InAppMessageLinkActionHandler") {

            var urlHandler: MockUrlHandler!
            var sut: InAppMessageLinkActionHandler!

            beforeEach {
                urlHandler = MockUrlHandler()
                urlHandler.reset()
                sut = InAppMessageLinkActionHandler(urlHandler: urlHandler)
            }

            it("supports") {
                expect(sut.supports(action: InAppMessage.action(type: .close))) == false
                expect(sut.supports(action: InAppMessage.action(type: .webLink))) == true
                expect(sut.supports(action: InAppMessage.action(type: .hidden))) == false
            }

            it("when action value is nil then do nothing") {
                // given
                let view = MockInAppMessageView(presented: true)
                let action = InAppMessage.action(type: .webLink, value: nil)

                // when
                sut.handle(view: view, action: action)

                // then - 비동기 작업이 실행될 시간을 준 후 호출되지 않음을 확인
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                expect(urlHandler.openCallCount).to(equal(0))
            }

            it("when invalid url then do nothing") {
                // given
                let view = MockInAppMessageView(presented: true)
                let action = InAppMessage.action(type: .webLink, value: "")

                // when
                sut.handle(view: view, action: action)

                // then - guard에서 early return되므로 Task 자체가 생성되지 않음
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                expect(urlHandler.openCallCount).to(equal(0))
            }

            it("hackle link") {
                // given
                let view = MockInAppMessageView(presented: true)
                let action = InAppMessage.action(type: .webLink, value: "https://www.hackle.io")

                // when
                sut.handle(view: view, action: action)

                // then - toEventually로 비동기 호출 대기
                expect(urlHandler.openCallCount).toEventually(equal(1), timeout: .seconds(1))
                expect(urlHandler.lastOpenedUrl?.absoluteString).to(equal("https://www.hackle.io"))
            }
        }

        describe("InAppMessageLinkAndCloseHandler") {
            var urlHandler: MockUrlHandler!
            var sut: InAppMessageLinkAndCloseHandler!

            beforeEach {
                urlHandler = MockUrlHandler()
                urlHandler.reset()
                sut = InAppMessageLinkAndCloseHandler(urlHandler: urlHandler)
            }

            it("supports") {
                expect(sut.supports(action: InAppMessage.action(type: .close))) == false
                expect(sut.supports(action: InAppMessage.action(type: .webLink))) == false
                expect(sut.supports(action: InAppMessage.action(type: .hidden))) == false
                expect(sut.supports(action: InAppMessage.action(type: .linkAndClose))) == true
            }

            it("when action value is nil then do nothing") {
                // given
                let view = MockInAppMessageView(presented: true)
                let action = InAppMessage.action(type: .linkAndClose, value: nil)

                // when
                sut.handle(view: view, action: action)

                // then - guard에서 early return되므로 dismiss도 호출되지 않음
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                expect(urlHandler.openCallCount).to(equal(0))
                expect(view.presented).to(beTrue())
            }

            it("when invalid url then do nothing") {
                // given
                let view = MockInAppMessageView(presented: true)
                let action = InAppMessage.action(type: .linkAndClose, value: "")

                // when
                sut.handle(view: view, action: action)

                // then - guard에서 early return
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                expect(urlHandler.openCallCount).to(equal(0))
                expect(view.presented).to(beTrue())
            }

            it("hackle link and close") {
                // given
                let view = MockInAppMessageView(presented: true)
                let action = InAppMessage.action(type: .linkAndClose, value: "https://www.hackle.io")

                // when
                sut.handle(view: view, action: action)

                // then - view.dismiss()는 동기적으로 호출되고, urlHandler.open은 비동기로 호출됨
                expect(view.presented).to(beFalse())
                expect(urlHandler.openCallCount).toEventually(equal(1), timeout: .seconds(1))
                expect(urlHandler.lastOpenedUrl?.absoluteString).to(equal("https://www.hackle.io"))
            }
        }

        describe("InAppMessageHiddenActionHandler") {
            var repository: KeyValueRepository!
            var storage: InAppMessageHiddenStorage!
            var sut: InAppMessageHiddenActionHandler!

            beforeEach {
                repository = MemoryKeyValueRepository()
                storage = DefaultInAppMessageHiddenStorage(keyValueRepository: repository)
                sut = InAppMessageHiddenActionHandler(clock: FixedClock(date: Date(timeIntervalSince1970: 42)), storage: storage)
            }

            it("supports") {
                expect(sut.supports(action: InAppMessage.action(type: .close))) == false
                expect(sut.supports(action: InAppMessage.action(type: .webLink))) == false
                expect(sut.supports(action: InAppMessage.action(type: .hidden))) == true
            }

            it("handle") {
                // given
                let context = InAppMessage.context(inAppMessage: InAppMessage.create(key: 42))
                let view = MockInAppMessageView(context: context, presented: true)
                let action = InAppMessage.action(type: .hidden)

                // when
                sut.handle(view: view, action: action)

                // then
                expect(repository.getDouble(key: "42")) == (60 * 60 * 24) + 42
            }
            
            it("when override, do not save hidden info") {
                // given
                let context = InAppMessage.context(inAppMessage: InAppMessage.create(key: 42), decisionReason: DecisionReason.OVERRIDDEN)
                let view = MockInAppMessageView(context: context, presented: true)
                let action = InAppMessage.action(type: .hidden)

                // when
                sut.handle(view: view, action: action)

                // then
                expect(repository.getDouble(key: "42")) == 0.0 // not saved
            }
        }
    }
}
