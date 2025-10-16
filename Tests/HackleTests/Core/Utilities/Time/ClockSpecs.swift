import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class ClockSpecs: QuickSpec {
    override func spec() {
        it("SystemClock") {
            expect(SystemClock.shared.currentMillis()) > 0
            expect(SystemClock.shared.tick()) > 0
        }
    }
}