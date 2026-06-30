//
//  EntitySpecs.swift
//  HackleTests
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class EntitySpecs: QuickSpec {

    override class func spec() {

        it("ServiceType raw values match server contract") {
            expect(ServiceType.abTest.rawValue).to(equal("AB_TEST"))
            expect(ServiceType.featureFlag.rawValue).to(equal("FEATURE_FLAG"))
            expect(ServiceType.remoteConfig.rawValue).to(equal("REMOTE_CONFIG"))
            expect(ServiceType.inAppMessage.rawValue).to(equal("IN_APP_MESSAGE"))
        }

        it("entityKey is equal when serviceType and id match") {
            let a = DefaultEntity(serviceType: .abTest, id: 1)
            let b = DefaultEntity(serviceType: .abTest, id: 1)
            expect(a.entityKey).to(equal(b.entityKey))
        }

        it("entityKey differs when serviceType differs") {
            let a = DefaultEntity(serviceType: .abTest, id: 1)
            let c = DefaultEntity(serviceType: .featureFlag, id: 1)
            expect(a.entityKey).notTo(equal(c.entityKey))
        }

        it("entityKey differs when id differs") {
            let a = DefaultEntity(serviceType: .abTest, id: 1)
            let d = DefaultEntity(serviceType: .abTest, id: 2)
            expect(a.entityKey).notTo(equal(d.entityKey))
        }
    }
}
