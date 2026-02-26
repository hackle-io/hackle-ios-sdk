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

class ApplicationUrlHandlerSpecs: QuickSpec {
    override func spec() {
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
        }
    }
}
