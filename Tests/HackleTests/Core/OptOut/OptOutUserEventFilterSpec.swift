import Foundation
import Quick
import Nimble
@testable import Hackle

class OptOutUserEventFilterSpec: QuickSpec {
    override func spec() {

        it("opt-out 상태이면 block") {
            let optOutManager = OptOutManager(configOptOutTracking: true)
            let sut = OptOutUserEventFilter(optOutManager: optOutManager)

            let actual = sut.check(event: UserEvents.track("test"))

            expect(actual).to(equal(UserEventFilterResult.block))
        }

        it("opt-in 상태이면 pass") {
            let optOutManager = OptOutManager(configOptOutTracking: false)
            let sut = OptOutUserEventFilter(optOutManager: optOutManager)

            let actual = sut.check(event: UserEvents.track("test"))

            expect(actual).to(equal(UserEventFilterResult.pass))
        }
    }
}
