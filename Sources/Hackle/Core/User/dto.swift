//
//  dto.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/16/25.
//

class IdentifierDto: Codable {
    var type: String
    var value: String
}

class UserCohortDto: Codable {
    var identifier: IdentifierDto
    var cohorts: [Int64]
}

class UserCohortsResponseDto: Codable {
    var cohorts: [UserCohortDto]
}

class UserTargetResponseDto: Codable {
    var events: [TargetEventDto]
}

class TargetEventDto: Codable {
    /// 타겟팅 할 이벤트
    let eventKey: String
    /// 이벤트 통계
    let stats: [StatDto]
    /// 타겟팅에 추가로 이용 할 이벤트 프로퍼티
    let property: PropertyDto?
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.eventKey = try container.decode(String.self, forKey: .eventKey)
        self.stats = try container.decode([StatDto].self, forKey: .stats)
        self.property = try? container.decode(PropertyDto.self, forKey: .property)
    }
}

class StatDto: Codable {
    let date: Int64
    let count: Int
}

class PropertyDto: Codable {
    /// 키
    let key: String
    /// 타입
    ///
    /// 현재는 EVENT_PROPERTY만 지원
    let type: Target.KeyType
    /// 값
    let value: HackleValue
}
