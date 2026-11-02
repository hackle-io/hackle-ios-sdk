import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleDelegateRegistrySpecs: QuickSpec {
    override class func spec() {
        describe("HackleDelegateRegistry") {
            afterEach {
                Hackle.setDelegate(nil)
            }

            it("delegate가 없으면 urlHandler.open을 호출한다") {
                let registry = HackleDelegateRegistry()
                let urlHandler = MockUrlHandler()
                let url = URL(string: "https://www.hackle.io")!
                MainActor.assumeIsolated {
                    registry.open(url: url, channel: .push, urlHandler: urlHandler)
                }
                expect(urlHandler.openedUrls) == [url]
            }

            it("delegate가 있으면 delegate만 호출하고 urlHandler는 호출하지 않는다") {
                let registry = HackleDelegateRegistry()
                let urlHandler = MockUrlHandler()
                let delegate = MockHackleDelegate()
                let url = URL(string: "myapp://home")!
                registry.setDelegate(delegate)
                MainActor.assumeIsolated {
                    registry.open(url: url, channel: .inAppMessage, urlHandler: urlHandler)
                }
                expect(delegate.contexts.count) == 1
                expect(delegate.contexts[0].url) == url
                expect(delegate.contexts[0].channel) == .inAppMessage
                expect(urlHandler.openCallCount) == 0
            }

            it("setDelegate(nil)이면 다시 urlHandler.open을 호출한다") {
                let registry = HackleDelegateRegistry()
                let urlHandler = MockUrlHandler()
                let delegate = MockHackleDelegate()
                let url = URL(string: "https://www.hackle.io")!
                registry.setDelegate(delegate)
                registry.setDelegate(nil)
                MainActor.assumeIsolated {
                    registry.open(url: url, channel: .push, urlHandler: urlHandler)
                }
                expect(urlHandler.openCallCount) == 1
                expect(delegate.contexts.isEmpty) == true
            }

            it("백그라운드 스레드에서 등록한 delegate가 메인에서 보인다") {
                let registry = HackleDelegateRegistry()
                let delegate = MockHackleDelegate()
                DispatchQueue.global().sync { registry.setDelegate(delegate) }
                expect(registry.delegate) === delegate
            }

            it("Hackle.setDelegate는 shared 레지스트리에 등록한다") {
                let delegate = MockHackleDelegate()
                Hackle.setDelegate(delegate)
                expect(HackleDelegateRegistry.shared.delegate) === delegate
            }

            it("교체된 delegate의 deinit에서 레지스트리에 재진입할 수 있다") {
                let registry = HackleDelegateRegistry()
                let newDelegate = MockHackleDelegate()
                var deinitCalled = false
                var delegateInDeinit: HackleDelegate?
                registry.setDelegate(DeinitHackleDelegate {
                    delegateInDeinit = registry.delegate
                    deinitCalled = true
                })
                registry.setDelegate(newDelegate)
                expect(deinitCalled) == true
                expect(delegateInDeinit) === newDelegate
            }

            it("제거된 delegate의 deinit에서 레지스트리에 재진입할 수 있다") {
                let registry = HackleDelegateRegistry()
                var deinitCalled = false
                var delegateInDeinit: HackleDelegate?
                registry.setDelegate(DeinitHackleDelegate {
                    delegateInDeinit = registry.delegate
                    deinitCalled = true
                })
                registry.setDelegate(nil)
                expect(deinitCalled) == true
                expect(delegateInDeinit).to(beNil())
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
