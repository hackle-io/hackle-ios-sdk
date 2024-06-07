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
            expect(screen).to(equal(Screen(name: "TestViewController", className: "TestViewController")))
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
