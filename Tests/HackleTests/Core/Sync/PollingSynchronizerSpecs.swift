import Foundation
import Nimble
import Quick
@testable import Hackle

class PollingSynchronizerSpecs: QuickSpec {
    override func spec() {

        describe("sync") {
            it("delegate") {
                // given
                let delegate = MockSynchronizer()
                let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: 10)

                // when
                sut.sync {
                }

                // then
                verify(exactly: 1) {
                    delegate.syncMock
                }
            }
        }

        describe("start") {
            it("no polling") {
                // given
                let delegate = MockSynchronizer()
                every(delegate.syncMock).answers({ $0(.success(())) })
                let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: -1)

                // when
                sut.start()
                Thread.sleep(forTimeInterval: 0.2)

                // then
                verify(exactly: 0) {
                    delegate.syncMock
                }
            }

            it("start scheduling") {
                // given
                let delegate = MockSynchronizer()
                every(delegate.syncMock).answers({ $0(.success(())) })
                let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: 0.1)

                // when
                sut.start()
                Thread.sleep(forTimeInterval: 0.25)

                // then
                verify(exactly: 2) {
                    delegate.syncMock
                }
            }

            it("start once") {
                // given
                let delegate = MockSynchronizer()
                every(delegate.syncMock).answers({ $0(.success(())) })
                let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: 0.1)

                // when
                let q = DispatchQueue(label: "test")
                for _ in 0..<10 {
                    q.async {
                        sut.start()
                    }
                }
                Thread.sleep(forTimeInterval: 0.25)

                // then
                verify(exactly: 2) {
                    delegate.syncMock
                }
            }
        }

        describe("stop") {
            it("no polling") {
                // given
                let delegate = MockSynchronizer()
                every(delegate.syncMock).answers({ $0(.success(())) })
                let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: -1)

                // when
                sut.start()
                sut.stop()
            }

            it("cancel polling job") {
                // given
                let delegate = MockSynchronizer()
                every(delegate.syncMock).answers({ $0(.success(())) })
                let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: 0.1)

                // when
                sut.start()
                Thread.sleep(forTimeInterval: 0.25)
                sut.stop()
                Thread.sleep(forTimeInterval: 0.25)

                // then
                verify(exactly: 2) {
                    delegate.syncMock
                }
            }
        }

        it("onChanged") {
            let delegate = MockSynchronizer()
            every(delegate.syncMock).answers({ $0(.success(())) })
            let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: 0.5)

            sut.onForeground(nil, timestamp: Date(), isFromBackground: true)
            Thread.sleep(forTimeInterval: 1.25)
            verify(exactly: 2) {
                delegate.syncMock
            }
            sut.onBackground(nil, timestamp: Date())
            Thread.sleep(forTimeInterval: 1.25)
            verify(exactly: 2) {
                delegate.syncMock
            }
        }
    }
}
