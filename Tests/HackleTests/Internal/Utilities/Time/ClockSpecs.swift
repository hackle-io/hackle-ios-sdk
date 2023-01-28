import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class ClockSpecs: QuickSpec {
    override func spec() {
        it("SystemClock") {
            expect(SystemClock.instance.currentMillis()) > 0
            expect(SystemClock.instance.tick()) > 0
        }
    }
}