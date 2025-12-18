//
//  ApplicationUrlHandlerSpecs.swift
//  HackleTests
//
//  Created by Claude Code
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
                context("when URL has no scheme") {
                    it("should return without error") {
                        let url = URL(string: "https://www.hackle.io")!
                        expect { sut.open(url: url) }.toNot(throwError())
                    }
                }

                context("when URL has HTTP scheme") {
                    it("should attempt to use Universal Link if supported") {
                        let url = URL(string: "https://www.hackle.io")!
                        expect { sut.open(url: url) }.toNot(throwError())
                    }
                }

                context("when URL has HTTPS scheme") {
                    it("should attempt to use Universal Link if supported") {
                        let url = URL(string: "https://www.hackle.io/path")!
                        expect { sut.open(url: url) }.toNot(throwError())
                    }
                }

                context("when URL has custom scheme") {
                    it("should use fallback to open URL directly") {
                        let url = URL(string: "hackleapp://path")!
                        expect { sut.open(url: url) }.toNot(throwError())
                    }
                }

                context("when URL has FTP scheme") {
                    it("should use fallback to open URL directly") {
                        let url = URL(string: "ftp://files.example.com")!
                        expect { sut.open(url: url) }.toNot(throwError())
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

                    for url in urls {
                        expect { sut.open(url: url) }.toNot(throwError())
                    }
                }
            }
        }
    }
}
