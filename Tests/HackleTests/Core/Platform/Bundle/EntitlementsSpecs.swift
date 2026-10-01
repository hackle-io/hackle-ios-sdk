import Foundation
import Quick
import Nimble
@testable import Hackle

class EntitlementsSpecs: QuickSpec {
    override class func spec() {
        describe("EntitlementsParser.applinks(data:)") {
            context("thin arm64 Mach-O에 슬롯 5 XML이 있으면") {
                it("applinks host 집합을 반환한다") {
                    let signature = MachOFixture.entitlementsSignature(associatedDomains: [
                        "applinks:example.com",
                        "applinks:*.hackle.io",
                        "applinks:dev.example.com?mode=developer",
                        "webcredentials:example.com",
                        "activitycontinuation:example.com",
                    ])
                    let data = MachOFixture.thin(signature: signature)
                    let result = EntitlementsParser.applinks(data: data)
                    expect(result) == Set(["example.com", "*.hackle.io", "dev.example.com"])
                }
            }

            context("associated-domains 키가 없으면") {
                it("빈 집합을 반환한다 (판별 불가가 아님)") {
                    let data = MachOFixture.thin(signature: MachOFixture.entitlementsSignature(associatedDomains: nil))
                    let result = EntitlementsParser.applinks(data: data)
                    expect(result) == Set<String>()
                }
            }

            context("LC_CODE_SIGNATURE 앞에 다른 로드 커맨드가 있으면") {
                it("건너뛰고 서명을 찾는다") {
                    let dummy = MachOFixture.le32(0x19) + MachOFixture.le32(24) + [UInt8](repeating: 0, count: 16)
                    let data = MachOFixture.thin(signature: MachOFixture.entitlementsSignature(associatedDomains: ["applinks:a.io"]), extraCommands: dummy)
                    let result = EntitlementsParser.applinks(data: data)
                    expect(result) == Set(["a.io"])
                }
            }

            context("SuperBlob에 슬롯 5 앞뒤로 다른 슬롯이 있으면") {
                it("슬롯 5만 읽는다") {
                    let signature = MachOFixture.signature(slots: [
                        (type: 0, magic: 0xfade0c02, payload: Data([1, 2, 3])),
                        (type: 5, magic: MachOFixture.entitlementsMagic, payload: MachOFixture.entitlementsPlist(associatedDomains: ["applinks:b.io"])),
                        (type: 7, magic: 0xfade7172, payload: Data([0x30, 0x00])),
                    ])
                    let data = MachOFixture.thin(signature: signature)
                    let result = EntitlementsParser.applinks(data: data)
                    expect(result) == Set(["b.io"])
                }
            }

            context("startIndex가 0이 아닌 Data 슬라이스를 넘기면") {
                it("상대 오프셋으로 동일하게 파싱한다") {
                    let thin = MachOFixture.thin(signature: MachOFixture.entitlementsSignature(associatedDomains: ["applinks:s.io"]))
                    let base = Data([9, 9]) + thin
                    let result = EntitlementsParser.applinks(data: base[2...])
                    expect(result) == Set(["s.io"])
                }
            }
        }

        describe("EntitlementsParser.applinks(from:)") {
            it("applinks 접두 항목만 추출하고 쿼리를 제거하며 소문자로 정규화한다") {
                let hosts = EntitlementsParser.applinks(from: [
                    "applinks:Example.COM",
                    "applinks:x.io?mode=developer",
                    "APPLINKS:y.io",
                    "webcredentials:z.io",
                    "applinks:",
                    "applinks: ",
                ])
                expect(hosts) == Set(["example.com", "x.io", "y.io"])
            }
        }

    }
}
