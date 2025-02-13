//
//  UserTargetEvents.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//


typealias UserTargetEvents = [TargetEvent]

extension UserTargetEvents {
    func toBuilder() -> Builder {
        Builder(targetEvents: self)
    }
}

extension UserTargetEvents {

    static func empty() -> UserTargetEvents {
        []
    }

    static func builder() -> Builder {
        Builder()
    }

    static func from(dto: UserTargetResponseDto) -> UserTargetEvents {
        dto.events.reduce(builder()) { builder, targetEvent in
            let property = targetEvent.property.map { property in
                TargetEvent.Property(key: property.key, type: property.type, value: property.value)
            }
            
            return builder.put(targetEvent: TargetEvent(
                eventKey: targetEvent.eventKey,
                stats: targetEvent.stats.map { stat in
                    TargetEvent.Stat(date: stat.date, count: stat.count)
                },
                property: property
            ))
        }
        .build()
    }

    class Builder {

        private var targetEvents = UserTargetEvents()

        init() {
        }

        init(targetEvents: UserTargetEvents) {
            self.targetEvents = targetEvents
        }

        func put(targetEvent: TargetEvent) -> Builder {
            self.targetEvents.append(targetEvent)
            return self
        }

        func putAll(targetEvents: UserTargetEvents) -> Builder {
            self.targetEvents.append(contentsOf: targetEvents)
            return self
        }

        func build() -> UserTargetEvents {
            targetEvents
        }
    }
}
