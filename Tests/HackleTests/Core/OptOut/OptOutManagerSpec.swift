import Foundation
import Quick
import Nimble
@testable import Hackle

class OptOutManagerSpec: QuickSpec {
    override func spec() {

        describe("init") {
            it("configOptOutTracking=false이면 opt-in") {
                let sut = OptOutManager(configOptOutTracking: false)
                expect(sut.isOptOutTracking).to(beFalse())
            }

            it("configOptOutTracking=true이면 opt-out") {
                let sut = OptOutManager(configOptOutTracking: true)
                expect(sut.isOptOutTracking).to(beTrue())
            }
        }

        describe("setOptOutTracking") {
            it("false에서 true로 변경") {
                let sut = OptOutManager(configOptOutTracking: false)

                sut.setOptOutTracking(optOut: true)

                expect(sut.isOptOutTracking).to(beTrue())
            }

            it("true에서 false로 변경") {
                let sut = OptOutManager(configOptOutTracking: true)

                sut.setOptOutTracking(optOut: false)

                expect(sut.isOptOutTracking).to(beFalse())
            }

            it("동일 값이면 변경 없음") {
                let sut = OptOutManager(configOptOutTracking: true)

                sut.setOptOutTracking(optOut: true)

                expect(sut.isOptOutTracking).to(beTrue())
            }
        }
    }
}
