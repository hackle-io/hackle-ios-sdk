import Foundation
import Quick
import Nimble
@testable import Hackle

class SerialTaskQueueSpecs: QuickSpec {
    override class func spec() {

        it("제출 순서(FIFO)대로 실행한다 - 첫 작업이 느려도 추월되지 않는다") {
            let sut = SerialTaskQueue()
            let executed = AtomicReference<[Int]>(value: [])

            sut.enqueue {
                try? await Task.sleep(nanoseconds: 100_000_000)
                executed.set(newValue: executed.get() + [0])
            }
            for i in 1..<50 {
                sut.enqueue {
                    executed.set(newValue: executed.get() + [i])
                }
            }

            // FIFO가 아니면 뒤 작업들이 0보다 먼저 완료되어 실패한다.
            // 작업들은 직렬 실행되므로 executed의 get+set 조합은 race가 없다.
            expect(executed.get()).toEventually(equal(Array(0..<50)), timeout: .seconds(10))
        }
    }
}
