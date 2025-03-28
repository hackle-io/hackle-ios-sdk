//
// Created by yong on 2020/12/11.
//

// https://github.com/jpedrosa/sua/blob/master/Sources/murmurhash3.swift
import Foundation

class Murmur3 {

    // MurmurHash3 32 bits.
    // Translated to Swift by referring to the following sources:
    // * https://github.com/jwerle/murmurhash.c
    // * https://en.wikipedia.org/wiki/MurmurHash
    public static func doHash32(key: UnsafePointer<UInt8>, maxBytes: Int,
                                seed: UInt32 = 0) -> UInt32 {
        let c1: UInt32 = 0xcc9e2d51
        let c2: UInt32 = 0x1b873593
        let r1: UInt32 = 15
        let r2: UInt32 = 13
        let m: UInt32 = 5
        let n: UInt32 = 0xe6546b64
        var hash: UInt32 = seed
        var k: UInt32 = 0
        let l = maxBytes / 4 // chunk length

        key.withMemoryRebound(to: UInt32.self, capacity: l) { (key32) -> Void in
            let chunks = UnsafeBufferPointer<UInt32>(
                start: UnsafePointer<UInt32>(key32), count: l)

            for chunk in chunks {
                k = chunk &* c1
                k = (k << r1) | (k >> (32 - r1))
                k = k &* c2
                hash ^= k
                hash = (hash << r2) | (hash >> (32 - r2))
                hash = ((hash &* m) &+ n)
            }
        }

        let tail = UnsafeBufferPointer<UInt8>(
            start: UnsafePointer<UInt8>(key) + (l * 4), count: 4)

        k = 0

        // remainder
        switch maxBytes & 3 { // `len % 4'
        case 3:
            k ^= UInt32(tail[2]) << 16
            fallthrough
        case 2:
            k ^= UInt32(tail[1]) << 8
            fallthrough
        case 1:
            k ^= UInt32(tail[0])
            k = k &* c1
            k = (k << r1) | (k >> (32 - r1))
            k = k &* c2
            hash ^= k
        default: () // Ignore.
        }

        hash ^= UInt32(maxBytes)

        hash ^= hash >> 16
        hash = hash &* 0x85ebca6b
        hash ^= hash >> 13
        hash = hash &* 0xc2b2ae35
        hash ^= hash >> 16

        return hash
    }

    public static func hash32(data: String, seed: UInt32) -> UInt32 {
        var a = [UInt8](data.utf8)
        return doHash32(key: &a, maxBytes: a.count, seed: seed)
    }
}
