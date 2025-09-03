import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageSchedulerFactorySpecs: QuickSpec {
    override func spec() {

        it("get") {
            let scheduler1 = MockInAppMessageScheduler()
            every(scheduler1.supportMock).returns(false)

            let scheduler2 = MockInAppMessageScheduler()
            every(scheduler2.supportMock).returns(true)

            let sut = DefaultInAppMessageSchedulerFactory(schedulers: [
                scheduler1, scheduler2,
            ])

            let actual = try sut.get(scheduleType: .triggered)

            expect(actual).to(beIdenticalTo(scheduler2))
        }

        it("exception") {
            let scheduler1 = MockInAppMessageScheduler()
            every(scheduler1.supportMock).returns(false)

            let scheduler2 = MockInAppMessageScheduler()
            every(scheduler2.supportMock).returns(false)

            let sut = DefaultInAppMessageSchedulerFactory(schedulers: [
                scheduler1, scheduler2,
            ])

            expect {
                try sut.get(scheduleType: .triggered)
            }.to(throwError())
        }
    }
}
