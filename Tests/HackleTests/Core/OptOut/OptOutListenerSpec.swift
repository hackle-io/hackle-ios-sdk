import Foundation
import Quick
import Nimble
@testable import Hackle

class OptOutListenerSpec: QuickSpec {
    override class func spec() {

        it("setOptOutTracking(true) 시 리스너에 onOptOutChanged(current: true) 호출") {
            let sut = OptOutManager(configOptOutTracking: false)
            let spy = OptOutListenerSpy()
            sut.addListener(listener: spy)

            sut.setOptOutTracking(optOut: true)

            expect(spy.callCount) == 1
            expect(spy.lastCurrent) == true
        }

        it("setOptOutTracking(false) 시 리스너에 onOptOutChanged(current: false) 호출") {
            let sut = OptOutManager(configOptOutTracking: true)
            let spy = OptOutListenerSpy()
            sut.addListener(listener: spy)

            sut.setOptOutTracking(optOut: false)

            expect(spy.callCount) == 1
            expect(spy.lastCurrent) == false
        }

        it("같은 값 설정 시 리스너 미호출") {
            let sut = OptOutManager(configOptOutTracking: true)
            let spy = OptOutListenerSpy()
            sut.addListener(listener: spy)

            sut.setOptOutTracking(optOut: true)

            expect(spy.callCount) == 0
        }

        it("상태 변경이 리스너 통지 전에 완료") {
            let sut = OptOutManager(configOptOutTracking: false)
            var stateAtNotification: Bool?
            let listener = BlockOptOutListener { current in
                stateAtNotification = current
            }
            sut.addListener(listener: listener)

            sut.setOptOutTracking(optOut: true)

            expect(stateAtNotification) == true
        }
    }
}

private class OptOutListenerSpy: OptOutListener {
    var callCount = 0
    var lastCurrent: Bool?

    func onOptOutChanged(current: Bool) {
        callCount += 1
        lastCurrent = current
    }
}

private class BlockOptOutListener: OptOutListener {
    private let block: (Bool) -> Void

    init(block: @escaping (Bool) -> Void) {
        self.block = block
    }

    func onOptOutChanged(current: Bool) {
        block(current)
    }
}
