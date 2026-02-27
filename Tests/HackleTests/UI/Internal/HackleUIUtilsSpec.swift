import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleUIUtilsSpec: QuickSpec {
    override func spec() {
        describe("UIUtils") {
            describe("currentScreen") {
                it("should return a valid UIScreen") {
                    let screen = MainActor.assumeIsolated { UIUtils.currentScreen }
                    expect(screen).notTo(beNil())
                }

                it("should have valid bounds") {
                    let screen = MainActor.assumeIsolated { UIUtils.currentScreen }
                    expect(screen.bounds.width).to(beGreaterThan(0))
                    expect(screen.bounds.height).to(beGreaterThan(0))
                }

                it("should have valid nativeBounds") {
                    let screen = MainActor.assumeIsolated { UIUtils.currentScreen }
                    expect(screen.nativeBounds.width).to(beGreaterThan(0))
                    expect(screen.nativeBounds.height).to(beGreaterThan(0))
                }

                it("nativeBounds should be greater than or equal to bounds") {
                    let screen = MainActor.assumeIsolated { UIUtils.currentScreen }
                    // nativeBounds는 scale factor가 적용되어 points bounds보다 크거나 같음
                    expect(screen.nativeBounds.width).to(beGreaterThanOrEqualTo(screen.bounds.width))
                    expect(screen.nativeBounds.height).to(beGreaterThanOrEqualTo(screen.bounds.height))
                }
            }
        }
    }
}
