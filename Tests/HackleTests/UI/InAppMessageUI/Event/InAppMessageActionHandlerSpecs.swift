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

                // then
                verify(exactly: 0) {
                    urlHandler.openMock
                }
            }

            it("when invalid url then do nothing") {
                // given
                let view = MockInAppMessageView(presented: true)
                let action = InAppMessage.action(type: .webLink, value: "")

                // when
                sut.handle(view: view, action: action)

                // then
                verify(exactly: 0) {
                    urlHandler.openMock
                }
            }

            it("hackle link") {
                // given
                let view = MockInAppMessageView(presented: true)
                let action = InAppMessage.action(type: .webLink, value: "https://www.hackle.io")

                // when
                sut.handle(view: view, action: action)

                // then
                verify {
                    urlHandler.openMock
                }
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
        }
    }
}