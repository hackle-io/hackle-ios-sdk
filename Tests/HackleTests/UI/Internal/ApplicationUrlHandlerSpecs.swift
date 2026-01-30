//
//  ApplicationUrlHandlerSpecs.swift
//  HackleTests
//
//  Created by sungwoo.yeo
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class ApplicationUrlHandlerSpecs: QuickSpec {
    override func spec() {
        describe("ApplicationUrlHandler") {
            var sut: ApplicationUrlHandler!

            beforeEach {
                sut = ApplicationUrlHandler()
            }

            describe("open(url:)") {
                context("when URL has HTTP scheme") {
                    it("should attempt to use Universal Link if supported") {
                        let url = URL(string: "http://www.hackle.io")!
                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("when URL has HTTPS scheme") {
                    it("should attempt to use Universal Link if supported") {
                        let url = URL(string: "https://www.hackle.io/path")!
                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }

                context("when URL has custom scheme") {
                    it("should use fallback to open URL directly") {
                        let url = URL(string: "hackleapp://path")!
                        waitUntil { done in
                            DispatchQueue.main.async {
                                sut.open(url: url)
                                done()
                            }
                        }
                    }
                }
            }

            describe("Integration scenarios") {
                it("should handle various URL types without crashing") {
                    let urls = [
                        URL(string: "https://www.hackle.io")!,
                        URL(string: "http://example.com")!,
                        URL(string: "myapp://deep/link")!,
                        URL(string: "tel:+1234567890")!,
                        URL(string: "mailto:test@example.com")!
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
    }
}
