import Foundation
import Nimble
import Quick
@testable import Hackle

class HackleInAppMessageUISpecs: AsyncSpec {
    override class func spec() {

        func htmlContext() -> InAppMessagePresentationContext {
            let layout = InAppMessage.Message.Layout(displayType: .html, layoutType: .none, alignment: nil)
            return InAppMessageEntity.context(message: InAppMessageEntity.message(layout: layout))
        }

        describe("present") {
            it("HTML 인앱 메시지가 비활성화되어 있으면 HTML 메시지를 노출하지 않는다") {
                let sut = makeInAppMessageUI(core: MockHackleCore(), htmlEnabled: false)

                let response = await sut.present(context: htmlContext())

                expect(response.code) == .htmlDisabled
            }

            it("HTML 인앱 메시지가 비활성화되어 있어도 다른 유형의 메시지는 막지 않는다") {
                let sut = makeInAppMessageUI(core: MockHackleCore(), htmlEnabled: false)

                let response = await sut.present(context: InAppMessageEntity.context())

                expect(response.code) != .htmlDisabled
            }

            it("HTML 인앱 메시지가 활성화되어 있으면 HTML 메시지를 막지 않는다") {
                let sut = makeInAppMessageUI(core: MockHackleCore(), htmlEnabled: true)

                let response = await sut.present(context: htmlContext())

                expect(response.code) != .htmlDisabled
            }
        }
    }
}
