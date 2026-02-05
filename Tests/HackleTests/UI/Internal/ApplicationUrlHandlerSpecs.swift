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

                context("유효한 URL") {
                    it("크래시 없이 처리해야 함") {
                        let url = URL(string: "https://www.hackle.io")!

                        // 테스트 환경: UIUtils.application이 nil이므로
                        // 실제 동작은 검증 불가, nil 안전성만 확인
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
}
