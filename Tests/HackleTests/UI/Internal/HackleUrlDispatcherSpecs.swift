import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleUrlDispatcherSpecs: QuickSpec {
    override class func spec() {
        describe("HackleUrlDispatcher") {
            it("주입한 handler로 channel과 함께 연다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlDispatcher(urlHandler: urlHandler)
                let url = URL(string: "https://www.hackle.io")!
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .push)
                }
                expect(urlHandler.openedUrls) == [url]
                expect(urlHandler.channels) == [.push]
            }

            it("DelegateUrlHandler로 교체하면 delegate만 호출한다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlDispatcher(urlHandler: urlHandler)
                let delegate = MockHackleDelegate()
                let url = URL(string: "myapp://home")!
                sut.setUrlHandler(DelegateUrlHandler(delegate: delegate))
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .inAppMessage)
                }
                expect(delegate.contexts.count) == 1
                expect(delegate.contexts[0].url) == url
                expect(delegate.contexts[0].channel) == .inAppMessage
                expect(urlHandler.openCallCount) == 0
            }

            it("다시 기본 handler로 교체하면 복귀한다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlDispatcher(urlHandler: urlHandler)
                let delegate = MockHackleDelegate()
                let url = URL(string: "https://www.hackle.io")!
                sut.setUrlHandler(DelegateUrlHandler(delegate: delegate))
                sut.setUrlHandler(urlHandler)
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .push)
                }
                expect(urlHandler.openCallCount) == 1
                expect(delegate.contexts.isEmpty) == true
            }

            it("백그라운드에서 교체한 handler가 메인 open에서 보인다") {
                let initial = MockUrlHandler()
                let installed = MockUrlHandler()
                let sut = HackleUrlDispatcher(urlHandler: initial)
                let url = URL(string: "https://example.com")!
                DispatchQueue.global().sync { sut.setUrlHandler(installed) }
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .push)
                }
                expect(installed.openedUrls) == [url]
                expect(initial.openCallCount) == 0
            }

            it("교체된 handler의 delegate deinit에서 setUrlHandler로 재진입할 수 있다") {
                let sut = HackleUrlDispatcher(urlHandler: MockUrlHandler())
                let deinitCalled = AtomicReference(value: false)
                sut.setUrlHandler(DelegateUrlHandler(delegate: DeinitHackleDelegate {
                    sut.setUrlHandler(MockUrlHandler())
                    deinitCalled.set(newValue: true)
                }))
                DispatchQueue.global().sync {
                    sut.setUrlHandler(MockUrlHandler())
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
