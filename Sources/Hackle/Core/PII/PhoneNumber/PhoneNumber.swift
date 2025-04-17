//
//  PhoneNumber.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation

struct PhoneNumber {
    let value: String
    
    static func create(phoneNumber: String) -> PhoneNumber {
        //let filterdValue = phoneNumber.filter { $0.isNumber || $0 == "+" }
        return PhoneNumber(value: phoneNumber)
    }
}
