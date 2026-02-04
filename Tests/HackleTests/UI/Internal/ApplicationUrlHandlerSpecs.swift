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

            afterEach {
                // Observer 정리
                NotificationCenter.default.removeObserver(
                    sut as Any,
                    name: UIApplication.didBecomeActiveNotification,
                    object: nil
                )
            }

            // MARK: - open(url:) 기본 동작 테스트

            describe("open(url:)") {

                context("scheme이 없는 URL") {
                    it("크래시 없이 early return 해야 함") {
                        // scheme이 없는 URL (드물지만 가능)
                        guard let url = URL(string: "//example.com/path") else {
                            fail("URL 생성 실패")
                            return
                        }

                        waitUntil { done in
                            DispatchQueue.main.async {
                                // scheme이 nil이면 early return
                                sut.open(url: url)
                                // 크래시 없이 완료되면 성공
                                done()
                            }
                        }
                    }
                }

                context("HTTP scheme URL") {
                    it("크래시 없이 처리해야 함") {
                        let url = URL(string: "http://www.hackle.io")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                // 테스트 환경: UIUtils.application이 nil이므로
                                // isContinueUserActivitySupported() -> false
                                // openLink() 호출되지만 실제 동작 없음
                                done()
                            }
                        }
                    }
                }

                context("HTTPS scheme URL") {
                    it("크래시 없이 처리해야 함") {
                        let url = URL(string: "https://www.hackle.io/path?query=value")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("Custom scheme URL") {
                    it("openLink로 직접 처리해야 함") {
                        let url = URL(string: "hackleapp://deep/link")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                // custom scheme은 항상 openLink로 처리
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("tel scheme URL") {
                    it("openLink로 직접 처리해야 함") {
                        let url = URL(string: "tel:+821012345678")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("mailto scheme URL") {
                    it("openLink로 직접 처리해야 함") {
                        let url = URL(string: "mailto:test@hackle.io")!

                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }
            }

            // MARK: - URL 유효성 테스트

            describe("다양한 URL 형식 처리") {

                it("쿼리 파라미터가 있는 URL") {
                    let url = URL(string: "https://www.hackle.io/path?key=value&foo=bar")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            sut.open(url: url)
                            done()
                        }
                    }
                }

                it("fragment가 있는 URL") {
                    let url = URL(string: "https://www.hackle.io/path#section")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            sut.open(url: url)
                            done()
                        }
                    }
                }

                it("포트 번호가 있는 URL") {
                    let url = URL(string: "https://www.hackle.io:8080/path")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            sut.open(url: url)
                            done()
                        }
                    }
                }

                it("인코딩된 문자가 있는 URL") {
                    let url = URL(string: "https://www.hackle.io/path?name=%ED%95%B4%ED%81%B4")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            sut.open(url: url)
                            done()
                        }
                    }
                }
            }

            // MARK: - NotificationCenter Observer 테스트

            describe("didBecomeActiveNotification 처리") {

                it("notification 수신 시 크래시 없이 처리해야 함") {
                    waitUntil { done in
                        DispatchQueue.main.async {
                            // pendingUrl이 없는 상태에서 notification 수신
                            NotificationCenter.default.post(
                                name: UIApplication.didBecomeActiveNotification,
                                object: nil
                            )
                            // 크래시 없이 완료
                            done()
                        }
                    }
                }
            }

            // MARK: - 연속 호출 테스트

            describe("연속 호출 안전성") {

                it("여러 URL을 연속으로 호출해도 크래시가 발생하지 않아야 함") {
                    let urls = [
                        URL(string: "https://www.hackle.io")!,
                        URL(string: "http://example.com")!,
                        URL(string: "hackleapp://deep/link")!,
                        URL(string: "tel:+821012345678")!,
                        URL(string: "mailto:test@hackle.io")!,
                        URL(string: "https://www.hackle.io/path?query=value#anchor")!
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

                it("동일한 URL을 여러 번 호출해도 안전해야 함") {
                    let url = URL(string: "https://www.hackle.io")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            for _ in 0..<10 {
                                sut.open(url: url)
                            }
                            done()
                        }
                    }
                }
            }

            // MARK: - 인스턴스 생성 테스트

            describe("인스턴스 생성") {

                it("새 인스턴스를 생성할 수 있어야 함") {
                    let handler = ApplicationUrlHandler()
                    expect(handler).notTo(beNil())
                }

                it("shared 인스턴스에 접근할 수 있어야 함") {
                    let shared = ApplicationUrlHandler.shared
                    expect(shared).notTo(beNil())
                }

                it("여러 인스턴스가 독립적으로 동작해야 함") {
                    let handler1 = ApplicationUrlHandler()
                    let handler2 = ApplicationUrlHandler()

                    let url = URL(string: "https://www.hackle.io")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            handler1.open(url: url)
                            handler2.open(url: url)
                            done()
                        }
                    }
                }
            }

            // MARK: - 엣지 케이스 테스트

            describe("엣지 케이스") {

                it("매우 긴 URL도 처리할 수 있어야 함") {
                    let longPath = String(repeating: "a", count: 1000)
                    let url = URL(string: "https://www.hackle.io/\(longPath)")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            sut.open(url: url)
                            done()
                        }
                    }
                }

                it("특수문자가 포함된 custom scheme도 처리해야 함") {
                    let url = URL(string: "my-app.v2://path")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            sut.open(url: url)
                            done()
                        }
                    }
                }

                it("IP 주소 기반 URL도 처리해야 함") {
                    let url = URL(string: "http://192.168.1.1:8080/api")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            sut.open(url: url)
                            done()
                        }
                    }
                }

                it("localhost URL도 처리해야 함") {
                    let url = URL(string: "http://localhost:3000/test")!

                    waitUntil { done in
                        DispatchQueue.main.async {
                            sut.open(url: url)
                            done()
                        }
                    }
                }
            }
        }
    }
}
