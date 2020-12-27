//
// Created by yong on 2020/12/11.
//

import Foundation

protocol Hasher {
    func hash(data: String, seed: Int32) -> Int32
}

class Murmur3Hasher: Hasher {
    func hash(data: String, seed: Int32) -> Int32 {
        let unsignedHash = Murmur3.hash32(data: data, seed: UInt32(truncatingIfNeeded: seed))

        if (unsignedHash & 0x80000000) == 0 {
            return Int32(unsignedHash)
        } else {
            return -Int32((unsignedHash ^ 0xffffffff) + 1)
        }
    }
}
