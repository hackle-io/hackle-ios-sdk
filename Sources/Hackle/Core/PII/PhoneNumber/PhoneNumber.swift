//
//  PhoneNumber.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation

class PhoneNumber {
    static func filtered(phoneNumber: String) -> String {
        let filtered = phoneNumber.filter { $0.isNumber || $0 == "+" }
        return String(filtered.prefix(16)) // + 제외 15자리 숫자가 e.164 표준
    }
}
