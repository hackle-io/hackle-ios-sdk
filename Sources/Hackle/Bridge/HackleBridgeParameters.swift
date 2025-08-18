//
//  HackleBridgeParameters.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

typealias HackleBridgeParameters = [String: Any?]

extension HackleBridgeParameters {
    /// 사용자 정보를 [String: Any] 형태로 반환합니다.
    /// - Returns: 사용자 정보 딕셔너리 또는 `nil`
    func userAsDictionary() -> [String: Any]? {
        self["user"] as? [String: Any]
    }
    
    /// id를 사용하는 User 객체를 반환합니다.
    /// - Returns: User 객체 또는 `nil`
    func user() -> User? {
        if let id = self["user"] as? String {
            return Hackle.user(id: id)
        }
        
        if let data = userAsDictionary(),
           let user = User.from(dto: data) {
            return user
        }
        
        return nil
    }
    
    /// userId를 사용하는 User 객체를 반환합니다.
    /// - Returns: User 객체 또는 `nil`
    func userWithUserId() -> User? {
        if let userId = self["user"] as? String {
            return Hackle.user(userId: userId)
        }
        
        if let data = userAsDictionary(),
           let user = User.from(dto: data) {
            return user
        }
        
        return nil
    }
    
    /// 사용자 ID를 반환합니다.
    /// - Returns: 사용자 ID 또는 `nil`
    func userId() -> String?? {
        self["userId"] as? String?
    }

    /// 기기 ID를 반환합니다.
    /// - Returns: 기기 ID 또는 `nil`
    func deviceId() -> String? {
        self["deviceId"] as? String
    }

    /// 프로퍼티의 키를 반환합니다.
    /// - Returns: 프로퍼티 키 또는 `nil`
    func key() -> String? {
        self["key"] as? String
    }

    /// 프로퍼티의 값을 반환합니다.
    /// - Returns: 프로퍼티 값 (`Any?`)
    func value() -> Any? {
        self["value"] ?? nil
    }

    /// UserProperty 업데이트를 위한 operations 객체를 `PropertyOperationsDto` 형태로 반환합니다.
    /// - Returns: PropertyOperationsDto 객체 또는 `nil`
    func propertyOperationDto() -> PropertyOperationsDto? {
        self["operations"] as? PropertyOperationsDto
    }

    /// HackleSubscriptionOperations 업데이트를 위한 operations 객체를 `HackleSubscriptionOperationsDto` 형태로 반환합니다.
    /// - Returns: HackleSubscriptionOperationsDto 객체 또는 `nil`
    func subscriptionOperationDto() -> HackleSubscriptionOperationsDto? {
        self["operations"] as? HackleSubscriptionOperationsDto
    }

    /// 사용자의 전화번호를 반환합니다.
    /// - Returns: 전화번호 또는 `nil`
    func phoneNumber() -> String? {
        self["phoneNumber"] as? String
    }

    /// 실험 키(Experiment Key)를 `Int64` 타입으로 반환합니다.
    /// - Returns: 실험 키 또는 `nil`
    func experimentKey() -> Int? {
        self["experimentKey"] as? Int
    }

    /// A/B 테스트의 기본 그룹(variation) 키를 반환합니다.
    /// - Returns: 기본 그룹 키. `nil`이 아님.
    func defaultVariation() -> String {
        (self["defaultVariation"] as? String) ?? "A"
    }

    /// 기능 플래그 키(Feature Key)를 `Int` 타입으로 반환합니다.
    /// - Returns: 기능 플래그 키 또는 `nil`
    func featureKey() -> Int? {
        self["featureKey"] as? Int
    }

    /// 트래킹할 이벤트를 반환합니다.
    /// - Returns: `Event` 객체, 또는 `nil`
    func event() -> Event? {
        if let eventKey = self["event"] as? String {
            return HackleEventBuilder(key: eventKey).build()
        }
        
        if let eventDto = self["event"] as? EventDto,
           let event = Event.from(dto: eventDto) {
            return event
        }
        
        return nil
    }

    /// 원격 구성(Remote Config)에서 가져올 값의 타입("string", "number", "boolean")을 반환합니다.
    /// - Returns: 값의 타입 또는 `nil`
    func valueType() -> String? {
        self["valueType"] as? String
    }

    /// 원격 구성(Remote Config) 조회 시 사용할 string 기본값을 반환합니다.
    /// - Returns: 기본값 (`Any?`)
    func defaultStringValue() -> String? {
        self["defaultValue"] as? String
    }
    
    // 원격 구성(Remote Config) 조회 시 사용할 double 기본값을 반환합니다.
    /// - Returns: 기본값 (`Any?`)
    func defaultDoubleValue() -> Double? {
        self["defaultValue"] as? Double
    }
    
    // 원격 구성(Remote Config) 조회 시 사용할 bool 기본값을 반환합니다.
    /// - Returns: 기본값 (`Any?`)
    func defaultBoolValue() -> Bool? {
        self["defaultValue"] as? Bool
    }

    /// 현재 화면의 이름을 반환합니다.
    /// - Returns: 화면 이름 또는 `nil`
    func screenName() -> String? {
        self["screenName"] as? String
    }

    /// 현재 화면의 클래스 이름을 반환합니다.
    /// - Returns: 클래스 이름 또는 `null`
    func className() -> String? {
        self["className"] as? String
    }
}
