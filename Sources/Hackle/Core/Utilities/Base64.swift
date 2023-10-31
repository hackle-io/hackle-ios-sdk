//
//  Base64.swift
//  Hackle
//
//  Created by Yong on 2023/10/15.
//

import Foundation


class Base64 {
    static func encodeUrl(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: ["="])
    }
}