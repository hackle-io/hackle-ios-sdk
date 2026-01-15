import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class ScreenSpecs: QuickSpec {
    override func spec() {

        it("create") {
            let vc = TestViewController()
            let screen = Screen.from(vc)
            let expectedScreen = Screen.builder(name: "TestViewController", className: "TestViewController").build()
            expect(screen).to(equal(expectedScreen))
        }

        it("screenClass") {
            let vc = TestViewController()
            let actual = Screen.screenClass(vc)
            expect(actual).to(equal("TestViewController"))
        }
    }

    private class TestViewController: UIViewController {
    }
}
