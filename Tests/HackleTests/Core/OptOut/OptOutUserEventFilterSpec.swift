import Foundation
import Quick
import Nimble
@testable import Hackle

class OptOutUserEventFilterSpec: QuickSpec {
    override func spec() {

        it("opt-out 상태이면 block") {
            let repository = MemoryKeyValueRepository()
            let optOutManager = OptOutManager(keyValueRepository: repository, configOptOutTracking: true)
            let sut = OptOutUserEventFilter(optOutManager: optOutManager)

            let actual = sut.check(event: UserEvents.track("test"))

            expect(actual).to(equal(UserEventFilterResult.block))
        }

        it("opt-in 상태이면 pass") {
            let repository = MemoryKeyValueRepository()
            let optOutManager = OptOutManager(keyValueRepository: repository, configOptOutTracking: false)
            let sut = OptOutUserEventFilter(optOutManager: optOutManager)

            let actual = sut.check(event: UserEvents.track("test"))

            expect(actual).to(equal(UserEventFilterResult.pass))
        }
    }
}
