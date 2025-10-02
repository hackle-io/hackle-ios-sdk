import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

class DefaultApplicationLifecycleManagerSpecs: QuickSpec {
    override func spec() {
        var queue: DispatchQueue!
        var listener: MockApplicationLifecycleListener!

        beforeEach {
            queue = DispatchQueue(label: "DefaultApplicationLifecycleManagerSpecs")
            listener = MockApplicationLifecycleListener()
        }

        describe("lifecycle events") {
            it("didBecomeActive") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)
                sut.addListener(listener: listener)

                sut.didBecomeActive()
                queue.await()
                expect(sut.currentState == .foreground).to(beTrue())
                verify(exactly: 1) {
                    listener.onForegroundMock
                }
            }
            it("didEnterBackground") {
                let sut = DefaultApplicationLifecycleManager.shared
                sut.setDispatchQueue(queue: queue)
                sut.addListener(listener: listener)

                sut.didEnterBackground()
                queue.await()
                expect(sut.currentState == .background).to(beTrue())
                verify(exactly: 1) {
                    listener.onBackgroundMock
                }
            }
        }
    }
}

