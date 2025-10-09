//
//  BundleVersionInfo.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/4/25.
//

struct BundleVersionInfo {
    let version: String
    let build: Int
}

extension BundleVersionInfo: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.version == rhs.version && lhs.build == rhs.build
    }
}
