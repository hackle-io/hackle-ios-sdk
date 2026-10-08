import Foundation

enum MachOFixture {
    static let machMagic64: UInt32 = 0xfeedfacf
    static let fatMagic: UInt32 = 0xcafebabe
    static let cpuTypeArm64: UInt32 = 0x0100000c
    static let cpuTypeX86_64: UInt32 = 0x01000007
    static let lcCodeSignature: UInt32 = 0x1d
    static let superBlobMagic: UInt32 = 0xfade0cc0
    static let entitlementsMagic: UInt32 = 0xfade7171
    static let entitlementsSlot: UInt32 = 5

    static var currentCpuType: UInt32 {
        #if arch(arm64)
        return cpuTypeArm64
        #else
        return cpuTypeX86_64
        #endif
    }

    static func le32(_ v: UInt32) -> [UInt8] {
        [UInt8(v & 0xff), UInt8((v >> 8) & 0xff), UInt8((v >> 16) & 0xff), UInt8((v >> 24) & 0xff)]
    }

    static func be32(_ v: UInt32) -> [UInt8] {
        [UInt8((v >> 24) & 0xff), UInt8((v >> 16) & 0xff), UInt8((v >> 8) & 0xff), UInt8(v & 0xff)]
    }

    static func entitlementsPlist(associatedDomains: [String]?) -> Data {
        var dict: [String: Any] = ["application-identifier": "TEAM.com.example.app"]
        if let associatedDomains {
            dict["com.apple.developer.associated-domains"] = associatedDomains
        }
        return (try? PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)) ?? Data()
    }

    static func blob(magic: UInt32, payload: Data) -> Data {
        var bytes = be32(magic) + be32(UInt32(8 + payload.count))
        bytes += [UInt8](payload)
        return Data(bytes)
    }

    static func signature(slots: [(type: UInt32, magic: UInt32, payload: Data)]) -> Data {
        var blobs: [Data] = []
        var indexBytes: [UInt8] = []
        var offset = 12 + 8 * slots.count
        for slot in slots {
            let b = blob(magic: slot.magic, payload: slot.payload)
            indexBytes += be32(slot.type) + be32(UInt32(offset))
            blobs.append(b)
            offset += b.count
        }
        var bytes = be32(superBlobMagic) + be32(UInt32(offset)) + be32(UInt32(slots.count)) + indexBytes
        for b in blobs { bytes += [UInt8](b) }
        return Data(bytes)
    }

    static func entitlementsSignature(associatedDomains: [String]?) -> Data {
        signature(slots: [(type: entitlementsSlot, magic: entitlementsMagic, payload: entitlementsPlist(associatedDomains: associatedDomains))])
    }

    static func header64(cpuType: UInt32, ncmds: UInt32, sizeofcmds: UInt32) -> [UInt8] {
        le32(machMagic64) + le32(cpuType) + le32(0) + le32(2) + le32(ncmds) + le32(sizeofcmds) + le32(0) + le32(0)
    }

    static func codeSignatureCommand(dataoff: UInt32, datasize: UInt32, cmdsize: UInt32 = 16) -> [UInt8] {
        le32(lcCodeSignature) + le32(cmdsize) + le32(dataoff) + le32(datasize)
    }

    static func thin(
        signature: Data?,
        cpuType: UInt32 = currentCpuType,
        extraCommands: [UInt8] = [],
        commandOverride: ((_ dataoff: UInt32, _ datasize: UInt32) -> [UInt8])? = nil
    ) -> Data {
        let padding = 64
        let sigSize = UInt32(signature?.count ?? 0)
        var commands = extraCommands
        let sigCommandSize = 16
        let dataoff = UInt32(32 + commands.count + sigCommandSize + padding)
        if let commandOverride {
            commands += commandOverride(dataoff, sigSize)
        } else if signature != nil {
            commands += codeSignatureCommand(dataoff: dataoff, datasize: sigSize)
        }
        let ncmds = UInt32((extraCommands.isEmpty ? 0 : 1) + (signature != nil || commandOverride != nil ? 1 : 0))
        var bytes = header64(cpuType: cpuType, ncmds: ncmds, sizeofcmds: UInt32(commands.count))
        bytes += commands
        bytes += [UInt8](repeating: 0, count: Int(dataoff) - bytes.count)
        if let signature { bytes += [UInt8](signature) }
        return Data(bytes)
    }

    static func fat(slices: [(cpuType: UInt32, data: Data)]) -> Data {
        var archBytes: [UInt8] = []
        var payload: [UInt8] = []
        var offset = 8 + 20 * slices.count
        offset = (offset + 4095) / 4096 * 4096
        for slice in slices {
            archBytes += be32(slice.cpuType) + be32(0) + be32(UInt32(offset)) + be32(UInt32(slice.data.count)) + be32(12)
            let start = offset - (8 + 20 * slices.count) - payload.count
            payload += [UInt8](repeating: 0, count: max(0, start))
            payload += [UInt8](slice.data)
            offset += slice.data.count
            offset = (offset + 4095) / 4096 * 4096
        }
        return Data(be32(fatMagic) + be32(UInt32(slices.count)) + archBytes + payload)
    }
}
