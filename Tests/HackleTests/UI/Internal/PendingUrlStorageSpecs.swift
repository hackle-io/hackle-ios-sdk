import Foundation
import Quick
import Nimble
@testable import Hackle

class PendingUrlStorageSpecs: QuickSpec {
    override class func spec() {
        describe("PendingUrlStorage") {
            it("마지막 1건만 유지한다") {
                let sut = PendingUrlStorage()
                let a = URL(string: "myapp://a")!
                let b = URL(string: "myapp://b")!
                MainActor.assumeIsolated {
                    sut.store(url: a)
                    sut.store(url: b)
                    expect(sut.pendingUrl) == b
                }
            }

            it("drain은 꺼내고 비운다") {
                let sut = PendingUrlStorage()
                let a = URL(string: "myapp://a")!
                MainActor.assumeIsolated {
                    sut.store(url: a)
                    expect(sut.drain()) == a
                    expect(sut.pendingUrl).to(beNil())
                    expect(sut.drain()).to(beNil())
                }
            }

            it("빈 상태 drain은 nil") {
                let sut = PendingUrlStorage()
                let drained = MainActor.assumeIsolated {
                    sut.drain()
                }
                expect(drained).to(beNil())
            }
        }
    }
}
