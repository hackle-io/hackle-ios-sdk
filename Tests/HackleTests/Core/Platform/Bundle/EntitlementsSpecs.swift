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

            func parse(_ data: Data) -> Set<String>? {
                EntitlementsParser.applinks(data: data)
            }

            let validSignature = MachOFixture.entitlementsSignature(associatedDomains: ["applinks:c.io"])
            let otherCpu = MachOFixture.currentCpuType == MachOFixture.cpuTypeArm64
                ? MachOFixture.cpuTypeX86_64
                : MachOFixture.cpuTypeArm64

            context("fat 바이너리") {
                it("현재 아키텍처 슬라이스를 골라 파싱한다") {
                    let other = MachOFixture.thin(signature: MachOFixture.entitlementsSignature(associatedDomains: ["applinks:wrong.io"]), cpuType: otherCpu)
                    let mine = MachOFixture.thin(signature: validSignature)
                    let data = MachOFixture.fat(slices: [(cpuType: otherCpu, data: other), (cpuType: MachOFixture.currentCpuType, data: mine)])
                    expect(parse(data)) == Set(["c.io"])
                }

                it("fat_no_matching_arch: 현재 아키텍처 슬라이스가 없으면 nil") {
                    let other = MachOFixture.thin(signature: validSignature, cpuType: otherCpu)
                    let data = MachOFixture.fat(slices: [(cpuType: otherCpu, data: other)])
                    expect(parse(data)).to(beNil())
                }

                it("슬라이스 offset이 파일 밖이면 nil") {
                    var bytes = [UInt8](MachOFixture.fat(slices: [(cpuType: MachOFixture.currentCpuType, data: MachOFixture.thin(signature: validSignature))]))
                    bytes.replaceSubrange(16..<20, with: MachOFixture.be32(0xffff_fff0))
                    expect(parse(Data(bytes))).to(beNil())
                }

                it("signature_outside_slice: 파일 안이어도 서명이 슬라이스 끝을 넘으면 nil") {
                    let thin = MachOFixture.thin(signature: validSignature)
                    var bytes = [UInt8](MachOFixture.fat(slices: [(cpuType: MachOFixture.currentCpuType, data: thin)]))
                    bytes.replaceSubrange(20..<24, with: MachOFixture.be32(UInt32(thin.count - 1)))
                    expect(parse(Data(bytes))).to(beNil())
                }

                it("슬라이스 크기가 헤더·로드 커맨드보다 작거나 파일 끝을 넘으면 nil") {
                    let thin = MachOFixture.thin(signature: validSignature)
                    let full = MachOFixture.fat(slices: [(cpuType: MachOFixture.currentCpuType, data: thin)])
                    for size in [UInt32(0), 31, 32, UInt32(thin.count + 1)] {
                        var bytes = [UInt8](full)
                        bytes.replaceSubrange(20..<24, with: MachOFixture.be32(size))
                        expect(parse(Data(bytes))).to(beNil())
                    }
                }

                it("nfat_arch가 상한을 넘으면 nil") {
                    var bytes = [UInt8](MachOFixture.fat(slices: [(cpuType: MachOFixture.currentCpuType, data: MachOFixture.thin(signature: validSignature))]))
                    bytes.replaceSubrange(4..<8, with: MachOFixture.be32(0x7fff_ffff))
                    expect(parse(Data(bytes))).to(beNil())
                }
            }

            context("판별 불가 입력") {
                it("빈 데이터") {
                    expect(parse(Data())).to(beNil())
                }

                it("매직 불일치") {
                    expect(parse(Data(repeating: 0x41, count: 4096))).to(beNil())
                }

                it("32비트 Mach-O 매직") {
                    var bytes = [UInt8](MachOFixture.thin(signature: validSignature))
                    bytes.replaceSubrange(0..<4, with: MachOFixture.le32(0xfeedface))
                    expect(parse(Data(bytes))).to(beNil())
                }

                it("헤더만 있고 나머지가 잘린 경우") {
                    let data = MachOFixture.thin(signature: validSignature)
                    expect(parse(data.prefix(32))).to(beNil())
                    expect(parse(data.prefix(40))).to(beNil())
                }

                it("LC_CODE_SIGNATURE 없음") {
                    let dummy = MachOFixture.le32(0x19) + MachOFixture.le32(24) + [UInt8](repeating: 0, count: 16)
                    let data = MachOFixture.thin(signature: nil, extraCommands: dummy)
                    expect(parse(data)).to(beNil())
                }

                it("cmdsize_zero: 로드 커맨드 cmdsize가 0이면 무한 루프 없이 nil") {
                    let data = MachOFixture.thin(signature: validSignature, commandOverride: { dataoff, datasize in
                        MachOFixture.codeSignatureCommand(dataoff: dataoff, datasize: datasize, cmdsize: 0)
                    })
                    expect(parse(data)).to(beNil())
                }

                it("cmdsize_overflow: cmdsize가 sizeofcmds를 넘으면 nil") {
                    let dummy = MachOFixture.le32(0x19) + MachOFixture.le32(0xffff_ff00) + [UInt8](repeating: 0, count: 16)
                    let data = MachOFixture.thin(signature: validSignature, extraCommands: dummy)
                    expect(parse(data)).to(beNil())
                }

                it("ncmds가 상한을 넘으면 nil") {
                    var bytes = [UInt8](MachOFixture.thin(signature: validSignature))
                    bytes.replaceSubrange(16..<20, with: MachOFixture.le32(0xffff_ffff))
                    expect(parse(Data(bytes))).to(beNil())
                }

                it("sizeofcmds가 파일 크기를 넘으면 nil") {
                    var bytes = [UInt8](MachOFixture.thin(signature: validSignature))
                    bytes.replaceSubrange(20..<24, with: MachOFixture.le32(0x00ff_ffff))
                    expect(parse(Data(bytes))).to(beNil())
                }

                it("dataoff가 파일 밖이면 nil") {
                    let data = MachOFixture.thin(signature: validSignature, commandOverride: { _, datasize in
                        MachOFixture.codeSignatureCommand(dataoff: 0xffff_fff0, datasize: datasize)
                    })
                    expect(parse(data)).to(beNil())
                }

                it("datasize가 파일 끝을 넘으면 nil") {
                    let data = MachOFixture.thin(signature: validSignature, commandOverride: { dataoff, datasize in
                        MachOFixture.codeSignatureCommand(dataoff: dataoff, datasize: datasize + 1)
                    })
                    expect(parse(data)).to(beNil())
                }

                it("datasize가 파일 크기를 크게 넘어도 nil") {
                    let data = MachOFixture.thin(signature: validSignature, commandOverride: { dataoff, _ in
                        MachOFixture.codeSignatureCommand(dataoff: dataoff, datasize: 0x7fff_ffff)
                    })
                    expect(parse(data)).to(beNil())
                }

                it("SuperBlob 매직 불일치") {
                    var sig = [UInt8](validSignature)
                    sig.replaceSubrange(0..<4, with: MachOFixture.be32(0xfade0c02))
                    expect(parse(MachOFixture.thin(signature: Data(sig)))).to(beNil())
                }

                it("superblob_length_bounds: 길이가 헤더·인덱스보다 작거나 서명 끝을 넘으면 nil") {
                    for size in [UInt32(0), 11, 12, 19, UInt32(validSignature.count + 1)] {
                        var sig = [UInt8](validSignature)
                        sig.replaceSubrange(4..<8, with: MachOFixture.be32(size))
                        expect(parse(MachOFixture.thin(signature: Data(sig)))).to(beNil())
                    }
                }

                it("slot_outside_superblob: 파일 안이어도 슬롯 5가 SuperBlob 끝을 넘으면 nil") {
                    for size in [20, 27, validSignature.count - 1] {
                        var sig = [UInt8](validSignature)
                        sig.replaceSubrange(4..<8, with: MachOFixture.be32(UInt32(size)))
                        expect(parse(MachOFixture.thin(signature: Data(sig)))).to(beNil())
                    }
                }

                it("signature_padding: SuperBlob 뒤의 서명 패딩은 허용한다") {
                    let padded = validSignature + Data(repeating: 0, count: 16)
                    expect(parse(MachOFixture.thin(signature: padded))) == Set(["c.io"])
                }

                it("huge_count: SuperBlob count가 상한을 넘으면 nil") {
                    var sig = [UInt8](validSignature)
                    sig.replaceSubrange(8..<12, with: MachOFixture.be32(0xffff_ffff))
                    expect(parse(MachOFixture.thin(signature: Data(sig)))).to(beNil())
                }

                it("count가 인덱스 영역보다 크면 nil") {
                    var sig = [UInt8](validSignature)
                    sig.replaceSubrange(8..<12, with: MachOFixture.be32(500))
                    expect(parse(MachOFixture.thin(signature: Data(sig)))).to(beNil())
                }

                it("index_offset_out_of_range: BlobIndex offset이 서명 영역 밖이면 nil") {
                    var sig = [UInt8](validSignature)
                    sig.replaceSubrange(16..<20, with: MachOFixture.be32(0xffff_fff0))
                    expect(parse(MachOFixture.thin(signature: Data(sig)))).to(beNil())
                }

                it("슬롯 5 없음") {
                    let sig = MachOFixture.signature(slots: [(type: 0, magic: 0xfade0c02, payload: Data([1, 2, 3]))])
                    expect(parse(MachOFixture.thin(signature: sig))).to(beNil())
                }

                it("슬롯 5 blob 매직 불일치") {
                    let sig = MachOFixture.signature(slots: [(type: 5, magic: 0xfade7172, payload: MachOFixture.entitlementsPlist(associatedDomains: ["applinks:d.io"]))])
                    expect(parse(MachOFixture.thin(signature: sig))).to(beNil())
                }

                it("blob length가 8보다 작으면 nil") {
                    var sig = [UInt8](validSignature)
                    sig.replaceSubrange(24..<28, with: MachOFixture.be32(4))
                    expect(parse(MachOFixture.thin(signature: Data(sig)))).to(beNil())
                }

                it("blob length가 서명 영역을 넘으면 nil") {
                    var sig = [UInt8](validSignature)
                    sig.replaceSubrange(24..<28, with: MachOFixture.be32(0x7fff_ffff))
                    expect(parse(MachOFixture.thin(signature: Data(sig)))).to(beNil())
                }

                it("plist가 깨졌으면 nil") {
                    let sig = MachOFixture.signature(slots: [(type: 5, magic: MachOFixture.entitlementsMagic, payload: Data("<plist><dict>".utf8))])
                    expect(parse(MachOFixture.thin(signature: sig))).to(beNil())
                }

                it("plist 루트가 dict가 아니면 nil") {
                    let payload = (try? PropertyListSerialization.data(fromPropertyList: ["a", "b"], format: .xml, options: 0)) ?? Data()
                    let sig = MachOFixture.signature(slots: [(type: 5, magic: MachOFixture.entitlementsMagic, payload: payload)])
                    expect(parse(MachOFixture.thin(signature: sig))).to(beNil())
                }

                it("associated-domains가 배열이 아니면 빈 집합") {
                    let payload = (try? PropertyListSerialization.data(fromPropertyList: ["com.apple.developer.associated-domains": "applinks:e.io"], format: .xml, options: 0)) ?? Data()
                    let sig = MachOFixture.signature(slots: [(type: 5, magic: MachOFixture.entitlementsMagic, payload: payload)])
                    expect(parse(MachOFixture.thin(signature: sig))) == Set<String>()
                }

                it("서명 영역 각 경계에서 잘려도 트랩 없이 nil") {
                    let full = MachOFixture.thin(signature: validSignature)
                    let sigStart = full.count - validSignature.count
                    for cut in [sigStart + 11, sigStart + 19, sigStart + 27, full.count - 1] {
                        expect(parse(full.prefix(cut))).to(beNil())
                    }
                }

                it("datasize를 잘린 크기에 맞춰도 SuperBlob 내부 경계에서 nil") {
                    let sigStart = 32 + 16 + 64
                    for cut in [11, 19, 27, validSignature.count - 1] {
                        var sig = [UInt8](validSignature.prefix(cut))
                        sig.replaceSubrange(4..<8, with: MachOFixture.be32(UInt32(cut)))
                        let data = MachOFixture.thin(signature: Data(sig), commandOverride: { _, _ in
                            MachOFixture.codeSignatureCommand(dataoff: UInt32(sigStart), datasize: UInt32(cut))
                        })
                        expect(parse(data)).to(beNil())
                    }
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
