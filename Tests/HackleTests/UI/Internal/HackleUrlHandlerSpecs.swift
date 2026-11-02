import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleUrlHandlerSpecs: QuickSpec {
    override class func spec() {
        describe("HackleUrlHandler") {
            afterEach {
                Hackle.setDelegate(nil)
            }

            it("delegate가 없으면 handler.open을 호출한다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlHandler(handler: urlHandler)
                let url = URL(string: "https://www.hackle.io")!
                MainActor.assumeIsolated {
                    sut.open(url: url, channel: .push)
                }
                expect(urlHandler.openedUrls) == [url]
            }

            it("delegate가 있으면 delegate만 호출하고 handler는 호출하지 않는다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlHandler(handler: urlHandler)
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

            it("setDelegate(nil)이면 다시 handler.open을 호출한다") {
                let urlHandler = MockUrlHandler()
                let sut = HackleUrlHandler(handler: urlHandler)
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

            it("백그라운드 스레드에서 등록한 delegate가 메인에서 보인다") {
                let sut = HackleUrlHandler()
                let delegate = MockHackleDelegate()
                DispatchQueue.global().sync { sut.setDelegate(delegate) }
                expect(sut.delegate) === delegate
            }

            it("Hackle.setDelegate는 shared에 등록한다") {
                let delegate = MockHackleDelegate()
                Hackle.setDelegate(delegate)
                expect(HackleUrlHandler.shared.delegate) === delegate
            }

            it("교체된 delegate의 deinit에서 재진입할 수 있다") {
                let sut = HackleUrlHandler()
                let newDelegate = MockHackleDelegate()
                var deinitCalled = false
                var delegateInDeinit: HackleDelegate?
                sut.setDelegate(DeinitHackleDelegate {
                    delegateInDeinit = sut.delegate
                    deinitCalled = true
                })
                sut.setDelegate(newDelegate)
                expect(deinitCalled) == true
                expect(delegateInDeinit) === newDelegate
            }

            it("제거된 delegate의 deinit에서 재진입할 수 있다") {
                let sut = HackleUrlHandler()
                var deinitCalled = false
                var delegateInDeinit: HackleDelegate?
                sut.setDelegate(DeinitHackleDelegate {
                    delegateInDeinit = sut.delegate
                    deinitCalled = true
                })
                sut.setDelegate(nil)
                expect(deinitCalled) == true
                expect(delegateInDeinit).to(beNil())
            }

            it("openPendingUrl은 보관된 링크를 delegate로 보낸다") {
                let pending = PendingUrlHandler()
                let sut = HackleUrlHandler(pending: pending)
                let delegate = MockHackleDelegate()
                let installed = MockUrlHandler()
                let url = URL(string: "https://example.com")!
                MainActor.assumeIsolated {
                    pending.open(url: url)
                    sut.setDelegate(delegate)
                    sut.setHandler(installed)
                    sut.openPendingUrl()
                }
                expect(delegate.contexts.map(\.url)) == [url]
                expect(delegate.contexts[0].channel) == .push
                expect(installed.openCallCount) == 0
            }

            it("delegate가 없으면 openPendingUrl이 보관 링크를 새 핸들러로 연다") {
                let pending = PendingUrlHandler()
                let sut = HackleUrlHandler(pending: pending)
                let installed = MockUrlHandler()
                let url = URL(string: "https://example.com")!
                MainActor.assumeIsolated {
                    pending.open(url: url)
                    sut.setHandler(installed)
                    sut.openPendingUrl()
                }
                expect(installed.openedUrls) == [url]
            }

            it("setHandler는 보관 링크를 열지 않는다") {
                let pending = PendingUrlHandler()
                let sut = HackleUrlHandler(pending: pending)
                let installed = MockUrlHandler()
                let url = URL(string: "https://example.com")!
                MainActor.assumeIsolated {
                    pending.open(url: url)
                    sut.setHandler(installed)
                    expect(pending.pendingUrl) == url
                }
                expect(installed.openCallCount) == 0
            }

            it("openPendingUrl을 두 번 호출해도 재전달하지 않는다") {
                let pending = PendingUrlHandler()
                let sut = HackleUrlHandler(pending: pending)
                let installed = MockUrlHandler()
                let url = URL(string: "https://example.com")!
                MainActor.assumeIsolated {
                    pending.open(url: url)
                    sut.setHandler(installed)
                    sut.openPendingUrl()
                    sut.openPendingUrl()
                }
                expect(installed.openedUrls) == [url]
            }

            it("setHandler 후 open은 새 핸들러로 간다") {
                let pending = PendingUrlHandler()
                let sut = HackleUrlHandler(pending: pending)
                let installed = MockUrlHandler()
                let url = URL(string: "https://example.com")!
                MainActor.assumeIsolated {
                    sut.setHandler(installed)
                    sut.openPendingUrl()
                    sut.open(url: url, channel: .push)
                    expect(pending.pendingUrl).to(beNil())
                }
                expect(installed.openedUrls) == [url]
            }
        }
    }
}

private final class DeinitHackleDelegate: NSObject, HackleDelegate {

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
