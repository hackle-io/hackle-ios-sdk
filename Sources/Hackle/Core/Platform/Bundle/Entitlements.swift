import Foundation

enum EntitlementsParser {
    private static let machMagic64: UInt32 = 0xfeedfacf
    private static let fatMagic: UInt32 = 0xcafebabe
    private static let cpuTypeArm64: UInt32 = 0x0100000c
    private static let cpuTypeX86_64: UInt32 = 0x01000007
    private static let lcCodeSignature: UInt32 = 0x1d
    private static let superBlobMagic: UInt32 = 0xfade0cc0
    private static let entitlementsMagic: UInt32 = 0xfade7171
    private static let entitlementsSlot: UInt32 = 5
    private static let associatedDomainsKey = "com.apple.developer.associated-domains"
    private static let applinksPrefix = "applinks:"

    private static let maxCount = 1024
    private static let maxBlobLength = 16 * 1024 * 1024
    private static let machHeader64Size = 32
    private static let fatHeaderSize = 8
    private static let fatArchSize = 20
    private static let loadCommandHeaderSize = 8
    private static let linkeditDataCommandSize = 16
    private static let superBlobHeaderSize = 12
    private static let blobIndexSize = 8
    private static let blobHeaderSize = 8

    private struct Region {
        let offset: Int
        let size: Int
    }

    private static var currentCpuType: UInt32 {
        #if arch(arm64)
        return cpuTypeArm64
        #else
        return cpuTypeX86_64
        #endif
    }

    static func applinks(data: Data) -> Set<String>? {
        guard let slice = machOSliceRegion(data),
              let signature = codeSignatureRegion(data, slice: slice),
              let plist = entitlementsPlist(data, signature: signature)
        else {
            return nil
        }
        let domains = plist[associatedDomainsKey] as? [String] ?? []
        return applinks(from: domains)
    }

    static func applinks(from domains: [String]) -> Set<String> {
        var hosts = Set<String>()
        for domain in domains {
            let lowered = domain.lowercased()
            guard lowered.hasPrefix(applinksPrefix) else {
                continue
            }
            var host = String(lowered.dropFirst(applinksPrefix.count))
            if let query = host.firstIndex(of: "?") {
                host = String(host[..<query])
            }
            host = host.trimmingCharacters(in: .whitespaces)
            if !host.isEmpty {
                hosts.insert(host)
            }
        }
        return hosts
    }

    private static func machOSliceRegion(_ data: Data) -> Region? {
        if data.uint32(at: 0, bigEndian: false) == machMagic64 {
            return Region(offset: 0, size: data.count)
        }
        guard data.uint32(at: 0, bigEndian: true) == fatMagic,
              let count = data.uint32(at: 4, bigEndian: true).map({ Int($0) }),
              count > 0, count <= maxCount,
              count * fatArchSize <= data.count - fatHeaderSize
        else {
            return nil
        }
        for i in 0..<count {
            let base = fatHeaderSize + i * fatArchSize
            guard let cpuType = data.uint32(at: base, bigEndian: true),
                  let offset = data.uint32(at: base + 8, bigEndian: true).map({ Int($0) }),
                  let size = data.uint32(at: base + 12, bigEndian: true).map({ Int($0) })
            else {
                return nil
            }
            if cpuType == currentCpuType {
                guard size >= machHeader64Size,
                      offset <= data.count, size <= data.count - offset,
                      data.uint32(at: offset, bigEndian: false) == machMagic64
                else {
                    return nil
                }
                return Region(offset: offset, size: size)
            }
        }
        return nil
    }

    private static func codeSignatureRegion(_ data: Data, slice: Region) -> Region? {
        guard slice.size >= machHeader64Size,
              let ncmds = data.uint32(at: slice.offset + 16, bigEndian: false).map({ Int($0) }),
              let sizeofcmds = data.uint32(at: slice.offset + 20, bigEndian: false).map({ Int($0) }),
              ncmds <= maxCount,
              sizeofcmds <= slice.size - machHeader64Size
        else {
            return nil
        }
        let commandsStart = slice.offset + machHeader64Size
        var cursor = 0
        for _ in 0..<ncmds {
            guard loadCommandHeaderSize <= sizeofcmds - cursor,
                  let cmd = data.uint32(at: commandsStart + cursor, bigEndian: false),
                  let cmdsize = data.uint32(at: commandsStart + cursor + 4, bigEndian: false).map({ Int($0) }),
                  cmdsize >= loadCommandHeaderSize, cmdsize <= sizeofcmds - cursor
            else {
                return nil
            }
            if cmd == lcCodeSignature {
                guard cmdsize >= linkeditDataCommandSize,
                      let dataoff = data.uint32(at: commandsStart + cursor + 8, bigEndian: false).map({ Int($0) }),
                      let datasize = data.uint32(at: commandsStart + cursor + 12, bigEndian: false).map({ Int($0) }),
                      datasize >= superBlobHeaderSize,
                      dataoff <= slice.size,
                      datasize <= slice.size - dataoff
                else {
                    return nil
                }
                return Region(offset: slice.offset + dataoff, size: datasize)
            }
            cursor += cmdsize
        }
        return nil
    }

    private static func entitlementsPlist(_ data: Data, signature: Region) -> [String: Any]? {
        guard data.uint32(at: signature.offset, bigEndian: true) == superBlobMagic,
              let superBlobSize = data.uint32(at: signature.offset + 4, bigEndian: true).map({ Int($0) }),
              superBlobSize >= superBlobHeaderSize, superBlobSize <= signature.size,
              let count = data.uint32(at: signature.offset + 8, bigEndian: true).map({ Int($0) }),
              count <= maxCount,
              count * blobIndexSize <= superBlobSize - superBlobHeaderSize
        else {
            return nil
        }
        for i in 0..<count {
            let indexOffset = signature.offset + superBlobHeaderSize + i * blobIndexSize
            guard let type = data.uint32(at: indexOffset, bigEndian: true),
                  let offset = data.uint32(at: indexOffset + 4, bigEndian: true).map({ Int($0) })
            else {
                return nil
            }
            guard type == entitlementsSlot else {
                continue
            }
            guard offset >= superBlobHeaderSize + count * blobIndexSize,
                  offset <= superBlobSize - blobHeaderSize,
                  data.uint32(at: signature.offset + offset, bigEndian: true) == entitlementsMagic,
                  let length = data.uint32(at: signature.offset + offset + 4, bigEndian: true).map({ Int($0) }),
                  length >= blobHeaderSize,
                  length <= maxBlobLength,
                  length <= superBlobSize - offset
            else {
                return nil
            }
            let start = data.startIndex + signature.offset + offset + blobHeaderSize
            let end = data.startIndex + signature.offset + offset + length
            let xml = Data(data[start..<end])
            let object = try? PropertyListSerialization.propertyList(from: xml, options: [], format: nil)
            return object as? [String: Any]
        }
        return nil
    }
}

private extension Data {
    func uint32(at offset: Int, bigEndian: Bool) -> UInt32? {
        guard offset >= 0, offset <= count - 4 else {
            return nil
        }
        let i = startIndex + offset
        let b0 = UInt32(self[i])
        let b1 = UInt32(self[i + 1])
        let b2 = UInt32(self[i + 2])
        let b3 = UInt32(self[i + 3])
        if bigEndian {
            return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
        }
        return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
    }
}
