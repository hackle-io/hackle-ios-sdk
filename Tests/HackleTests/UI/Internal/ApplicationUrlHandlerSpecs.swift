//
//  ApplicationUrlHandlerSpecs.swift
//  HackleTests
//
//  Created by sungwoo.yeo
//

import Foundation
import Quick
import Nimble
import UIKit
@testable import Hackle

@MainActor private func route(
    policy: UniversalLinkPolicy,
    applinks: Set<String>? = nil,
    scene: Bool,
    application: Bool?,
    url: URL
) -> MockUserActivityHandler {
    let mock = MockUserActivityHandler()
    mock.sceneSupported = scene
    mock.applicationResult = application
    let handler = ApplicationUrlHandler(
        policy: policy,
        entitlements: { Entitlements(applinks: applinks) },
        userActivityHandler: mock
    )
    handler.open(url: url)
    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    withExtendedLifetime(handler) {}
    return mock
}

@MainActor private func route(
    applinks: Set<String>?,
    scene: Bool,
    application: Bool?,
    url: URL
) -> MockUserActivityHandler {
    route(policy: .applinksOnly, applinks: applinks, scene: scene, application: application, url: url)
}

@MainActor private func countingHandler(policy: UniversalLinkPolicy) -> (ApplicationUrlHandler, AtomicInt64) {
    let calls = AtomicInt64(value: 0)
    let mock = MockUserActivityHandler()
    mock.sceneSupported = true
    let handler = ApplicationUrlHandler(
        policy: policy,
        entitlements: {
            calls.incrementAndGet()
            return Entitlements(applinks: ["example.com"])
        },
        userActivityHandler: mock
    )
    return (handler, calls)
}

class ApplicationUrlHandlerSpecs: QuickSpec {
    override class func spec() {
        describe("ApplicationUrlHandler") {
            var sut: ApplicationUrlHandler!

            beforeEach {
                sut = ApplicationUrlHandler()
            }

            // MARK: - 인스턴스 생성

            describe("인스턴스 생성") {
                it("새 인스턴스를 생성할 수 있어야 함") {
                    let handler = ApplicationUrlHandler()
                    expect(handler).notTo(beNil())
                }
            }

            // MARK: - open(url:) 기본 동작
            // 테스트 환경에서 UIUtils.application이 nil이므로
            // 실제 URL 열기/Universal Link 동작은 검증 불가, nil 안전성만 확인

            describe("open(url:)") {
                context("scheme이 없는 URL") {
                    it("크래시 없이 early return 해야 함") {
                        guard let url = URL(string: "//example.com/path") else {
                            fail("URL 생성 실패")
                            return
                        }

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("HTTPS URL") {
                    it("크래시 없이 처리해야 함") {
                        let url = URL(string: "https://www.hackle.io")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("HTTP URL") {
                    it("크래시 없이 처리해야 함") {
                        let url = URL(string: "http://www.hackle.io")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("커스텀 scheme URL") {
                    it("크래시 없이 openLink 경로로 처리해야 함") {
                        let url = URL(string: "hackle://deeplink/test")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("query, fragment가 포함된 URL") {
                    it("크래시 없이 처리해야 함") {
                        let url = URL(string: "https://www.hackle.io/path?key=value#section")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("연속 호출") {
                    it("여러 URL을 빠르게 연속 호출해도 크래시 없이 처리해야 함") {
                        let urls = [
                            URL(string: "https://www.hackle.io")!,
                            URL(string: "hackle://deeplink")!,
                            URL(string: "http://example.com")!,
                        ]

                        waitUntil { done in
                            DispatchQueue.main.async {
                                for url in urls {
                                    sut.open(url: url)
                                }
                                done()
                            }
                        }
                    }
                }
            }

            // MARK: - Notification observer 안전성

            describe("didBecomeActiveNotification") {
                context("pendingUrl이 없는 상태에서 notification이 발생하면") {
                    it("크래시 없이 무시해야 함") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(
                                    name: UIApplication.didBecomeActiveNotification,
                                    object: nil
                                )
                                done()
                            }
                        }
                    }
                }
            }

            // MARK: - deinit observer 정리

            describe("deinit") {
                it("해제 시 observer가 정리되어 이후 notification에도 크래시 없어야 함") {
                    var handler: ApplicationUrlHandler? = ApplicationUrlHandler()
                    _ = handler
                    handler = nil

                    waitUntil { done in
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(
                                name: UIApplication.didBecomeActiveNotification,
                                object: nil
                            )
                            done()
                        }
                    }
                }
            }

            describe("http/https 라우팅") {
                let url = URL(string: "https://example.com/promo")!

                context("매칭") {
                    it("scene delegate가 있으면 scene으로만 전달한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(applinks: ["example.com"], scene: true, application: true, url: url)
                                expect(mock.sceneUrls) == [url]
                                expect(mock.applicationUrls).to(beEmpty())
                                done()
                            }
                        }
                    }

                    it("scene delegate가 없으면 AppDelegate로 전달한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                for result in [true, false] {
                                    let mock = route(applinks: ["example.com"], scene: false, application: result, url: url)
                                    expect(mock.sceneUrls).to(beEmpty())
                                    expect(mock.applicationUrls) == [url]
                                }
                                done()
                            }
                        }
                    }

                    it("둘 다 없어도 크래시 없이 종료한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(applinks: ["example.com"], scene: false, application: nil, url: url)
                                expect(mock.sceneUrls).to(beEmpty())
                                expect(mock.applicationUrls).to(beEmpty())
                                done()
                            }
                        }
                    }

                    it("와일드카드 항목에도 매칭한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(applinks: ["*.com"], scene: true, application: nil, url: url)
                                expect(mock.sceneUrls) == [url]
                                done()
                            }
                        }
                    }
                }

                context("비매칭") {
                    it("scene·AppDelegate 어느 쪽도 호출하지 않는다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(applinks: ["other.io"], scene: true, application: true, url: url)
                                expect(mock.sceneUrls).to(beEmpty())
                                expect(mock.applicationUrls).to(beEmpty())
                                done()
                            }
                        }
                    }

                    it("associated-domains가 비어 있어도 호출하지 않는다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(applinks: [], scene: true, application: true, url: url)
                                expect(mock.sceneUrls).to(beEmpty())
                                expect(mock.applicationUrls).to(beEmpty())
                                done()
                            }
                        }
                    }
                }

                context("판별 불가") {
                    it("scene을 건너뛰고 AppDelegate로 전달한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(applinks: nil, scene: true, application: false, url: url)
                                expect(mock.sceneUrls).to(beEmpty())
                                expect(mock.applicationUrls) == [url]
                                done()
                            }
                        }
                    }

                    it("unresolved_unsupported_opens_immediately: AppDelegate 미구현이면 pending 없이 즉시 openLink 경로") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = MockUserActivityHandler()
                                let handler = ApplicationUrlHandler(
                                    policy: .applinksOnly,
                                    entitlements: { Entitlements(applinks: nil) },
                                    userActivityHandler: mock
                                )
                                handler.open(url: url)
                                expect(handler.hasPendingUrl) == false
                                expect(mock.applicationUrls).to(beEmpty())
                                done()
                            }
                        }
                    }
                }

                context("forwardAll") {
                    it("forwardAll_unmatched_to_scene: 비매칭 URL도 scene으로 전달한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(policy: .forwardAll, scene: true, application: true, url: url)
                                expect(mock.sceneUrls) == [url]
                                expect(mock.applicationUrls).to(beEmpty())
                                done()
                            }
                        }
                    }

                    it("scene delegate가 없으면 AppDelegate로 전달한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(policy: .forwardAll, scene: false, application: false, url: url)
                                expect(mock.sceneUrls).to(beEmpty())
                                expect(mock.applicationUrls) == [url]
                                done()
                            }
                        }
                    }

                    it("둘 다 없어도 크래시 없이 종료한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let mock = route(policy: .forwardAll, scene: false, application: nil, url: url)
                                expect(mock.sceneUrls).to(beEmpty())
                                expect(mock.applicationUrls).to(beEmpty())
                                done()
                            }
                        }
                    }
                }

                context("커스텀 스킴") {
                    it("정책·매칭 여부와 무관하게 delegate를 호출하지 않는다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                for policy in [UniversalLinkPolicy.applinksOnly, .forwardAll] {
                                    let mock = MockUserActivityHandler()
                                    mock.sceneSupported = true
                                    mock.applicationResult = true
                                    let handler = ApplicationUrlHandler(
                                        policy: policy,
                                        entitlements: { Entitlements(applinks: ["example.com"]) },
                                        userActivityHandler: mock
                                    )
                                    handler.open(url: URL(string: "hackle://example.com/x")!)
                                    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
                                    expect(mock.sceneUrls).to(beEmpty())
                                    expect(mock.applicationUrls).to(beEmpty())
                                    withExtendedLifetime(handler) {}
                                }
                                done()
                            }
                        }
                    }
                }

                context("entitlement 공급자 호출 횟수") {
                    it("핸들러 생성만으로는 호출하지 않는다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let (handler, calls) = countingHandler(policy: .applinksOnly)
                                expect(calls.get()) == 0
                                withExtendedLifetime(handler) {}
                                done()
                            }
                        }
                    }

                    it("forwardAll의 http/https 처리에서 호출하지 않는다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let (handler, calls) = countingHandler(policy: .forwardAll)
                                handler.open(url: url)
                                NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
                                expect(calls.get()) == 0
                                withExtendedLifetime(handler) {}
                                done()
                            }
                        }
                    }

                    it("applinksOnly의 커스텀 스킴 처리에서 호출하지 않는다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let (handler, calls) = countingHandler(policy: .applinksOnly)
                                handler.open(url: URL(string: "hackle://example.com/x")!)
                                expect(calls.get()) == 0
                                withExtendedLifetime(handler) {}
                                done()
                            }
                        }
                    }

                    it("applinksOnly의 http/https 판별에서 링크당 한 번 호출한다") {
                        waitUntil { done in
                            DispatchQueue.main.async {
                                let (handler, calls) = countingHandler(policy: .applinksOnly)
                                handler.open(url: url)
                                NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
                                expect(calls.get()) == 1
                                withExtendedLifetime(handler) {}
                                done()
                            }
                        }
                    }

                }
            }
        }
    }
}
