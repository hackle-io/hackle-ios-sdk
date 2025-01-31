//
//  PropertyKey.swift
//  Hackle
//
//  Created by sungwoo.yeo on 1/31/25.
//

struct PropertyKey: Codable {
    let type: `Type`
    let name: String
    
    enum `Type`: Codable {
        case cohort
        case hackle
        case user
        case event
    }
}
