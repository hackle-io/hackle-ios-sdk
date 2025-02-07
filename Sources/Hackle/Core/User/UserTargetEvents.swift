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
            builder.put(targetEvent: targetEvent)
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
