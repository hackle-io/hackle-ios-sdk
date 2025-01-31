//
//  TargetSegmentationExpression.swift
//  Hackle
//
//  Created by sungwoo.yeo on 1/31/25.
//

import Foundation

/// Targeting Segmentation Expression
protocol TargetSegmentationExpression {
    /// Target Key
    var type: Target.KeyType { get }
}

/// 기간 동안 이벤트 발생 횟수
class NumberOfEventsInDays: TargetSegmentationExpression, Codable {
    /// 이벤트 키
    let eventKey: String
    /// 기간
    let timeRange: TargetSegmentationOption.TimeRange
    /// 추가 필터
    let filters: [TargetSegmentationOption.PropertyFilter]?
    
    var type: Target.KeyType {
        get {
            .numberOfEventsInDays
        }
    }
    /// 최대 기간 (30일)
    private static let MAX_DAY_PERIOD: Int = 30
    
    init(eventKey: String, timeRange: TargetSegmentationOption.TimeRange, filters: [TargetSegmentationOption.PropertyFilter]?) throws {
        self.eventKey = eventKey
        self.timeRange = timeRange
        self.filters = filters
        
        guard timeRange.periodDays <= NumberOfEventsInDays.MAX_DAY_PERIOD else {
            throw HackleError.error("period max value 30, input value : \(timeRange.periodDays)")
        }
    }
}

extension String {
    func toNumberOfEventsInDays() throws -> NumberOfEventsInDays {
        let data = self.data(using: .utf8)!
        return try JSONDecoder().decode(NumberOfEventsInDays.self, from: data)
    }
}
