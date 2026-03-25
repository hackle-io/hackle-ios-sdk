import Foundation
@testable import Hackle
import Nimble
import Quick

class HtmlViewBridgeScriptSpecs: QuickSpec {
    override func spec() {
        typealias BridgeScript = HackleInAppMessageUI.HtmlViewBridgeScript
        typealias Loader = HackleInAppMessageUI.WebViewResourceLoader

        let thisFilePath = #filePath

        describe("javascriptSdkResource") {
            it("check fileName") {
                expect(BridgeScript.javascriptSdkResource).to(equal("hackle-javascript-sdk-\(BridgeScript.javascriptSdkVersion).min.js"))
            }

            it("check file exists") {
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
                let filePath = resourcesDir!.appendingPathComponent(BridgeScript.javascriptSdkResource).path
                expect(FileManager.default.fileExists(atPath: filePath)).to(beTrue())
            }

            it("check script") {
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
                let filePath = resourcesDir!.appendingPathComponent(BridgeScript.javascriptSdkResource).path
                let script = try! String(contentsOfFile: filePath, encoding: .utf8)

                // Check Javascript SDK Version
                expect(script).to(contain(BridgeScript.javascriptSdkVersion))

                // Check bridge function
                expect(script).to(contain(BridgeScript.bridgeFunctionName))

                // Check InvocationCommand
                InvocationCommand.allCases
                    .filter { $0 != .setCurrentScreen } // Not supported yet
                    .forEach {
                        expect(script).to(contain($0.rawValue))
                    }
            }

            it("check Package.swift") {
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
                expect(content).to(contain(BridgeScript.javascriptSdkResource))
            }

            it("check Bundle") {
                let fileURL = URL(fileURLWithPath: BridgeScript.javascriptSdkResource)
                let name = fileURL.deletingPathExtension().lastPathComponent
                let ext = fileURL.pathExtension

                let bundleURL = HackleInternalResources.bundle.url(forResource: name, withExtension: ext)
                expect(bundleURL).toNot(beNil())
            }
        }

        describe("bridgeFunctionName") {
            it("check functionName") {
                expect(BridgeScript.bridgeFunctionName).to(equal("setAppWebViewInAppMessageBridge"))
            }
        }

        describe("create") {
            it("default") {
                let expectedURL = Loader.resourceURL(fileName: BridgeScript.javascriptSdkResource).absoluteString
                let sut = BridgeScript.create(config: .DEFAULT)
                expect(sut.source).to(contain(expectedURL))
            }

            it("custom") {
                let expectedDefaultUrl = Loader.resourceURL(fileName: BridgeScript.javascriptSdkResource).absoluteString
                let customURL = "https://cdn.example.com/custom-sdk.js"
                let builder = HackleConfigBuilder()
                builder.extra["$javascript_sdk_url"] = customURL
                let config = builder.build()

                let sut = BridgeScript.create(config: config)

                expect(sut.source).to(contain(customURL))
                expect(sut.source).toNot(contain(expectedDefaultUrl))
            }
        }

        it("check inject source") {
            let sut = BridgeScript.create(config: .DEFAULT)
            let source = sut.source

            expect(source).to(contain("document.createElement('script')"))
            expect(source).to(contain("Hackle.\(BridgeScript.bridgeFunctionName)()"))
            expect(source).to(contain("document.head.appendChild(s)"))
        }
    }
}
