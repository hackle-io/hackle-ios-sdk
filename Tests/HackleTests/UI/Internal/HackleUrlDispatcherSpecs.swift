import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleUrlDispatcherSpecs: QuickSpec {
    override class func spec() {
        describe("HackleUrlDispatcher") {
            it("기본 handler로 channel과 함께 연다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlDispatcher(defaultHandler: urlHandler)
                let url = URL(string: "https://www.hackle.io")!
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .push)
                }
                expect(urlHandler.openedUrls) == [url]
                expect(urlHandler.channels) == [.push]
            }

            it("delegate를 등록하면 delegate만 호출한다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlDispatcher(defaultHandler: urlHandler)
                let delegate = MockHackleDelegate()
                let url = URL(string: "myapp://home")!
                sut.setDelegate(delegate)
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .inAppMessage)
                }
                expect(delegate.contexts.count) == 1
                expect(delegate.contexts[0].url) == url
                expect(delegate.contexts[0].channel) == .inAppMessage
                expect(urlHandler.openCallCount) == 0
            }

            it("delegate를 nil로 등록하면 기본 handler로 복귀한다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlDispatcher(defaultHandler: urlHandler)
                let delegate = MockHackleDelegate()
                let url = URL(string: "https://www.hackle.io")!
                sut.setDelegate(delegate)
                sut.setDelegate(nil)
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .push)
                }
                expect(urlHandler.openCallCount) == 1
                expect(delegate.contexts.isEmpty) == true
            }

            it("백그라운드에서 등록한 delegate가 메인 open에서 보인다") {
                let urlHandler = MockUrlHandler()
                let delegate = MockHackleDelegate()
                let sut = HackleUrlDispatcher(defaultHandler: urlHandler)
                let url = URL(string: "https://example.com")!
                DispatchQueue.global().sync { sut.setDelegate(delegate) }
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .push)
                }
                expect(delegate.contexts.map(\.url)) == [url]
                expect(urlHandler.openCallCount) == 0
            }

            it("교체된 delegate의 deinit에서 setDelegate로 재진입할 수 있다") {
                let sut = HackleUrlDispatcher(defaultHandler: MockUrlHandler())
                let deinitCalled = AtomicReference(value: false)
                sut.setDelegate(DeinitHackleDelegate {
                    sut.setDelegate(nil)
                    deinitCalled.set(newValue: true)
                })
                DispatchQueue.global().sync {
                    sut.setDelegate(nil)
                }
                expect(deinitCalled.get()) == true
            }
        }
    }
}

private final class DeinitHackleDelegate: NSObject, HackleDelegate, @unchecked Sendable {

    private let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void) {
        self.onDeinit = onDeinit
    }

    deinit {
        onDeinit()
    }

    @MainActor func handleURL(_ context: HackleURLContext) {
    }
}
