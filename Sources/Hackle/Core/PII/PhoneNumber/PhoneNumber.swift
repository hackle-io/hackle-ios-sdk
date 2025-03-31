//
//  PhoneNumber.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation

class PhoneNumber {
    private static let pattern = "^\\+[0-9]{1,15}$" // +로 시작하고 1~15자리 숫자
    private static let regex = try! NSRegularExpression(pattern: pattern, options: [])
    
    static func tryParse(phoneNumber: String) -> String? {
        if phoneNumber.isEmpty {
            return nil
        }
        
        let cleanedPhoneNumber = phoneNumber.replacingOccurrences(of: "[ .()-]", with: "", options: .regularExpression) // + 제외 특수문자 삭제
        guard regex.firstMatch(in: cleanedPhoneNumber, range: NSRange(location: 0, length: cleanedPhoneNumber.count)) != nil else {
            return nil
        }
        
        return cleanedPhoneNumber
    }
}
