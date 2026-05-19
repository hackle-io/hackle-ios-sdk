import Foundation
import Quick
import Nimble
@testable import Hackle


class RecursiveLockSpecs: QuickSpec {
    override class func spec() {

        it("같은 스레드에서 재진입해도 deadlock 없이 통과한다") {
            let lock = RecursiveLock(label: "io.hackle.test.RecursiveLock")

            let result: Int = lock.locked {
                return lock.locked {
                    return lock.locked {
                        return 42
                    }
                }
            }

            expect(result) == 42
        }

        it("throw하면 unlock 후 에러 전파") {
            let lock = RecursiveLock(label: "io.hackle.test.RecursiveLock")

            struct E: Error {}
            expect {
                try lock.locked { throw E() }
            }.to(throwError())

            // 같은 lock을 다시 사용해도 정상 동작 (unlock 보장)
            let value: Int = lock.locked { 1 }
            expect(value) == 1
        }

        it("다른 스레드에서 mutual exclusion") {
            let lock = RecursiveLock(label: "io.hackle.test.RecursiveLock")
            var counter = 0
            let iterations = 1000
            let group = DispatchGroup()

            for _ in 0..<4 {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for _ in 0..<iterations {
                        lock.locked {
                            counter += 1
                        }
                    }
                }
            }

            group.wait()
            expect(counter) == 4 * iterations
        }
    }
}
