import Foundation
@testable import Hackle
import Nimble
import Quick

class WebViewResourceLoaderSpecs: QuickSpec {
    override class func spec() {
        typealias Loader = HackleInAppMessageUI.WebViewResourceLoader

        var sut: Loader!

        beforeEach {
            sut = Loader()
        }

        describe("resourceURL(fileName:)") {
            it("converts a file name to a custom-scheme URL") {
                let url = Loader.resourceURL(fileName: "sdk.min.js")
                expect(url.absoluteString).to(equal("hackle-resource://cache.hackle/sdk.min.js"))
            }
        }

        describe("fileName(from:)") {
            it("extracts file name from a valid custom-scheme URL") {
                let url = URL(string: "hackle-resource://cache.hackle/sdk.min.js")!
                expect(Loader.fileName(from: url)).to(equal("sdk.min.js"))
            }

            it("returns nil for a https scheme") {
                let url = URL(string: "https://cache.hackle/sdk.min.js")!
                expect(Loader.fileName(from: url)).to(beNil())
            }

            it("returns nil for a mismatched domain") {
                let url = URL(string: "hackle-resource://other.host/sdk.min.js")!
                expect(Loader.fileName(from: url)).to(beNil())
            }

            it("returns nil for baseURL without a path component") {
                let url = Loader.baseURL
                expect(Loader.fileName(from: url)).to(beNil())
            }
        }

        describe("round-trip") {
            it("fileName(from: resourceURL(fileName:)) returns the original file name") {
                let fileName = "hackle-javascript-sdk-11.55.0.min.js"
                let url = Loader.resourceURL(fileName: fileName)
                expect(Loader.fileName(from: url)).to(equal(fileName))
            }
        }

        describe("load(url:)") {
            it("loads a bundled JS file and returns a WebResource") {
                let url = Loader.resourceURL(fileName: "hackle-javascript-sdk-11.55.0.min.js")
                let resource = sut.load(url: url)
                expect(resource).toNot(beNil())
                expect(resource?.mimeType).to(equal("application/javascript"))
                expect(resource?.encoding).to(equal("utf-8"))
                expect(resource?.data.isEmpty).to(beFalse())
            }

            it("returns nil for a non-existent bundle file") {
                let url = Loader.resourceURL(fileName: "non-existent.js")
                expect(sut.load(url: url)).to(beNil())
            }

            it("returns nil for a https scheme") {
                let url = URL(string: "https://cache.hackle/file.js")!
                expect(sut.load(url: url)).to(beNil())
            }

            it("returns nil for a file name without an extension") {
                let url = Loader.resourceURL(fileName: "noextension")
                expect(sut.load(url: url)).to(beNil())
            }
        }
    }
}
