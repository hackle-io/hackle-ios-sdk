//
//  TargetEvent.swift
//  Hackle
//
//  Created by sungwoo.yeo on 1/24/25.
//

import Foundation


/// Audience 타겟팅을 위한 Event 객체
struct TargetEvent: Decodable {
    /// 타겟팅 할 이벤트
    let eventKey: String
    /// 이벤트 통계
    let stats: [Stat]
    /// 타겟팅에 추가로 이용 할 이벤트 프로퍼티
    let property: Property?
    
    
    struct Property: Decodable {
        let key: String
        let value: HackleValue
    }
    
    struct Stat: Decodable {
        let date: Int64
        let count: Int
    }
}
