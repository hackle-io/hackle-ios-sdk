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
    
    required init(from decoder: Decoder) throws {
        guard let container = try? decoder.container(keyedBy: CodingKeys.self),
              let key = try? container.decode(String.self, forKey: .key),
              let value = try? container.decode(HackleValue.self, forKey: .value),
              let typeString = try? container.decode(String.self, forKey: .type),
              let targetKeyType = TargetKeyTypeDto.from(rawValue: typeString)?.type else {
            throw HackleError.error("")
        }

        self.key = key
        self.value = value
        self.type = targetKeyType
    }
}

struct TargetKeyTypeDto {
    let type: Target.KeyType
    
    private init(type: Target.KeyType) {
        self.type = type
    }
    
    static func from(rawValue: String) -> TargetKeyTypeDto? {
        guard let targetKeyType = Target.KeyType(rawValue: rawValue) else {
            Log.info("Unsupported type[\(rawValue)]. Please use the latest version of sdk.")
            return nil
        }
        
        return TargetKeyTypeDto(type: targetKeyType)
    }
}
