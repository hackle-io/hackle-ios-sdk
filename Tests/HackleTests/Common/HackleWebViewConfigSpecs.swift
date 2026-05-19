//
//  HackleWebViewConfigSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/29/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class HackleWebViewConfigSpecs: QuickSpec {
    override class func spec() {
        describe("HackleWebViewConfig") {

            describe("builder") {
                it("should build with all properties set") {
                    let config = HackleWebViewConfig.builder()
                        .automaticRouteTracking(false)
                        .automaticScreenTracking(true)
                        .automaticEngagementTracking(true)
                        .build()

                    expect(config.automaticRouteTracking) == false
                    expect(config.automaticScreenTracking) == true
                    expect(config.automaticEngagementTracking) == true
                }

                it("should build with default values") {
                    let config = HackleWebViewConfig.builder().build()

                    expect(config.automaticRouteTracking) == true
                    expect(config.automaticScreenTracking) == false
                    expect(config.automaticEngagementTracking) == false
                }

                it("should support fluent interface") {
                    let builder = HackleWebViewConfig.builder()
                    let result0 = builder.automaticRouteTracking(false)
                    let result1 = builder.automaticScreenTracking(true)
                    let result2 = builder.automaticEngagementTracking(false)

                    expect(result0).to(beIdenticalTo(builder))
                    expect(result1).to(beIdenticalTo(builder))
                    expect(result2).to(beIdenticalTo(builder))
                }

                it("should allow partial configuration") {
                    let config = HackleWebViewConfig.builder()
                        .automaticScreenTracking(true)
                        .build()

                    expect(config.automaticRouteTracking) == true
                    expect(config.automaticScreenTracking) == true
                    expect(config.automaticEngagementTracking) == false
                }
            }

            describe("DEFAULT") {
                it("should have correct default values") {
                    let config = HackleWebViewConfig.DEFAULT

                    expect(config.automaticRouteTracking) == true
                    expect(config.automaticScreenTracking) == false
                    expect(config.automaticEngagementTracking) == false
                }
            }

            describe("Encodable") {
                it("should encode to JSON correctly with all false") {
                    let config = HackleWebViewConfig.builder().build()
                    let encoder = JSONEncoder()

                    let jsonData = try? encoder.encode(config)
                    expect(jsonData).toNot(beNil())

                    let jsonString = String(data: jsonData!, encoding: .utf8)
                    expect(jsonString).toNot(beNil())
                    expect(jsonString).toNot(beEmpty())
                }

                it("should encode JSON with automaticScreenTracking") {
                    let config = HackleWebViewConfig.builder()
                        .automaticScreenTracking(true)
                        .build()

                    let encoder = JSONEncoder()
                    let jsonData = try? encoder.encode(config)
                    let jsonString = String(data: jsonData!, encoding: .utf8)

                    expect(jsonString).to(contain("automaticScreenTracking"))
                    expect(jsonString).to(contain("true"))
                }

                it("should encode JSON with automaticEngagementTracking") {
                    let config = HackleWebViewConfig.builder()
                        .automaticEngagementTracking(true)
                        .build()

                    let encoder = JSONEncoder()
                    let jsonData = try? encoder.encode(config)
                    let jsonString = String(data: jsonData!, encoding: .utf8)

                    expect(jsonString).to(contain("automaticEngagementTracking"))
                    expect(jsonString).to(contain("true"))
                }

                it("should encode JSON with all properties") {
                    let config = HackleWebViewConfig.builder()
                        .automaticRouteTracking(true)
                        .automaticScreenTracking(true)
                        .automaticEngagementTracking(false)
                        .build()

                    let encoder = JSONEncoder()
                    let jsonData = try? encoder.encode(config)
                    let jsonString = String(data: jsonData!, encoding: .utf8)!

                    expect(jsonString).to(contain("automaticRouteTracking"))
                    expect(jsonString).to(contain("automaticScreenTracking"))
                    expect(jsonString).to(contain("automaticEngagementTracking"))
                    expect(jsonString).toNot(beEmpty())
                }

                it("should encode JSON with automaticRouteTracking") {
                    let config = HackleWebViewConfig.builder()
                        .automaticRouteTracking(false)
                        .build()

                    let encoder = JSONEncoder()
                    let jsonData = try? encoder.encode(config)
                    let jsonString = String(data: jsonData!, encoding: .utf8)

                    expect(jsonString).to(contain("automaticRouteTracking"))
                    expect(jsonString).to(contain("false"))
                }
            }
        }
    }
}
