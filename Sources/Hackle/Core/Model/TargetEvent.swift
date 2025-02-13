//
//  TargetEvent.swift
//  Hackle
//
//  Created by sungwoo.yeo on 1/24/25.
//

import Foundation


/// Audience 타겟팅을 위한 Event 객체
struct TargetEvent {
    /// 타겟팅 할 이벤트
    let eventKey: String
    /// 이벤트 통계
    let stats: [Stat]
    /// 타겟팅에 추가로 이용 할 이벤트 프로퍼티
    let property: Property?
    
    /// 프로퍼티 정보
    struct Property {
        /// 키
        let key: String
        /// 타입
        ///
        /// 현재는 EVENT_PROPERTY만 지원
        let type: Target.KeyType
        /// 값
        let value: HackleValue
    }
    
    /// 이벤트 발생 통계
    struct Stat {
        /// 발생 일자
        ///
        /// Unix Timestamp
        let date: Int64
        /// 발생 횟수
        let count: Int
    }
}

extension TargetEvent: Equatable {
    static func == (lhs: TargetEvent, rhs: TargetEvent) -> Bool {
        lhs.eventKey == rhs.eventKey && lhs.property == rhs.property
    }
}

extension TargetEvent.Property: Equatable {
    static func == (lhs: TargetEvent.Property, rhs: TargetEvent.Property) -> Bool {
        lhs.key == rhs.key && lhs.type == rhs.type && lhs.value == rhs.value
    }
}
