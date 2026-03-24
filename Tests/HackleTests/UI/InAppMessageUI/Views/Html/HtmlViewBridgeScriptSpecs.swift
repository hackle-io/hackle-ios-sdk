import Foundation
@testable import Hackle
import Nimble
import Quick

class HtmlViewBridgeScriptSpecs: QuickSpec {
    override func spec() {

        typealias BridgeScript = HackleInAppMessageUI.HtmlViewBridgeScript
        typealias Loader = HackleInAppMessageUI.WebViewResourceLoader

        // Test-owned expected value — must be updated together with the JS SDK file.
        // If this value is stale, the tests below will pinpoint which step was missed.
        let expectedResource = "hackle-javascript-sdk-11.55.0.min.js"

        let thisFilePath = #filePath

        describe("javascriptSdkResource consistency") {

            it("matches the test-expected file name") {
                expect(BridgeScript.javascriptSdkResource).to(equal(expectedResource))
            }

            it("exists as a file in the Resources directory") {
                var dir = URL(fileURLWithPath: thisFilePath).deletingLastPathComponent()
                var resourcesDir: URL?
                for _ in 0..<10 {
                    let candidate = dir.appendingPathComponent("Sources/Hackle/Resources")
                    if FileManager.default.fileExists(atPath: candidate.path) {
                        resourcesDir = candidate
                        break
                    }
                    dir = dir.deletingLastPathComponent()
                }

                expect(resourcesDir).toNot(beNil())
                let filePath = resourcesDir!.appendingPathComponent(expectedResource).path
                expect(FileManager.default.fileExists(atPath: filePath)).to(beTrue())
            }

            it("is registered in Package.swift") {
                var dir = URL(fileURLWithPath: thisFilePath).deletingLastPathComponent()
                var content: String?
                for _ in 0..<10 {
                    let candidate = dir.appendingPathComponent("Package.swift")
                    if let text = try? String(contentsOf: candidate, encoding: .utf8) {
                        content = text
                        break
                    }
                    dir = dir.deletingLastPathComponent()
                }

                expect(content).toNot(beNil())
                expect(content).to(contain(expectedResource))
            }

            it("is loadable from the app bundle") {
                let fileURL = URL(fileURLWithPath: expectedResource)
                let name = fileURL.deletingPathExtension().lastPathComponent
                let ext = fileURL.pathExtension

                let bundleURL = HackleInternalResources.bundle.url(forResource: name, withExtension: ext)
                expect(bundleURL).toNot(beNil())
            }
        }

        describe("create(config:)") {
            it("uses the default custom-scheme URL when no override is set") {
                let sut = BridgeScript.create(config: .DEFAULT)
                let expectedURL = Loader.resourceURL(fileName: expectedResource).absoluteString

                expect(sut.source).to(contain(expectedURL))
            }

            it("uses the override URL from config when set") {
                let customURL = "https://cdn.example.com/custom-sdk.js"
                let builder = HackleConfigBuilder()
                builder.extra["$javascript_sdk_url"] = customURL
                let config = builder.build()

                let sut = BridgeScript.create(config: config)

                expect(sut.source).to(contain(customURL))
                expect(sut.source).toNot(contain(Loader.resourceURL(fileName: expectedResource).absoluteString))
            }
        }

        describe("source") {
            it("generates a valid script injection snippet") {
                let sut = BridgeScript.create(config: .DEFAULT)
                let source = sut.source

                expect(source).to(contain("document.createElement('script')"))
                expect(source).to(contain("Hackle.setWebAppInAppMessageHtmlBridge()"))
                expect(source).to(contain("document.head.appendChild(s)"))
            }
        }
    }
}
