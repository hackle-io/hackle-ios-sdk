import Foundation

struct WorkspaceConfigRecordDto: Codable {
    var lastModified: String?   // 영속 JSON 키 — modifiedAt로 개명 금지 (하위호환)
    var config: WorkspaceConfigDto
}

class WorkspaceConfigDto: Codable {
    var workspace: WorkspaceDto
    var experiments: [ExperimentDto]
    var featureFlags: [ExperimentDto]
    var buckets: [BucketDto]
    var segments: [SegmentDto]
    var containers: [ContainerDto]
    var parameterConfigurations: [ParameterConfigurationDto]
    var remoteConfigParameters: [RemoteConfigParameterDto]
    var inAppMessages: [InAppMessageDto]
}

class WorkspaceDto: Codable {
    var id: Int64
    var environment: EnvironmentDto
}

class EnvironmentDto: Codable {
    var id: Int64
}

class ExperimentDto: Codable {
    var id: Int64
    var key: Int64
    var order: Int64?
    var name: String?
    var identifierType: String
    var status: String
    var version: Int
    var bucketId: Int64
    var variations: [VariationDto]
    var execution: ExecutionDto
    var winnerVariationId: Int64?
    var containerId: Int64?
}

class VariationDto: Codable {
    var id: Int64
    var key: String
    var status: String
    var parameterConfigurationId: Int64?
}

class ExecutionDto: Codable {
    var status: String
    var version: Int
    var userOverrides: [UserOverrideDto]
    var segmentOverrides: [TargetRuleDto]
    var targetAudiences: [TargetDto]
    var targetRules: [TargetRuleDto]
    var defaultRule: TargetActionDto
}

class UserOverrideDto: Codable {
    var userId: String
    var variationId: Int64
}

class BucketDto: Codable {
    var id: Int64
    var seed: Int32
    var slotSize: Int32
    var slots: [SlotDto]
}

class SlotDto: Codable {
    var startInclusive: Int
    var endExclusive: Int
    var variationId: Int64
}

class TargetDto: Codable {
    var conditions: [ConditionDto]

    class ConditionDto: Codable {
        var key: KeyDto
        var match: MatchDto
    }

    class KeyDto: Codable {
        var type: String
        var name: String
    }

    class MatchDto: Codable {
        var type: String
        var matchOperator: String
        var valueType: String
        var values: [HackleValue]

        enum CodingKeys: String, CodingKey {
            case type
            case matchOperator = "operator"
            case valueType
            case values
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)
            matchOperator = try container.decode(String.self, forKey: .matchOperator)
            valueType = try container.decode(String.self, forKey: .valueType)
            values = try container.decode([HackleValue].self, forKey: .values)
        }
    }

    class NumberOfEventsInDaysDto: Codable {
        /// 이벤트 키
        var eventKey: String
        /// 기간
        var days: Int
    }

    class NumberOfEventsWithPropertyInDaysDto: Codable {
        /// 이벤트 키
        var eventKey: String
        /// 기간
        var days: Int
        /// 프로퍼티 필터
        var propertyFilter: ConditionDto
    }
}

class TargetActionDto: Codable {
    var type: String
    var variationId: Int64?
    var bucketId: Int64?
}

class TargetRuleDto: Codable {
    var target: TargetDto
    var action: TargetActionDto
}

class SegmentDto: Codable {
    var id: Int64
    var key: String
    var type: String
    var targets: [TargetDto]
}

class ContainerDto: Codable {
    var id: Int64
    var bucketId: Int64
    var groups: [ContainerGroupDto]
}

class ContainerGroupDto: Codable {
    var id: Int64
    var experiments: [Int64]
}

class ParameterConfigurationDto: Codable {
    var id: Int64
    var parameters: [ParameterDto]
}

class ParameterDto: Codable {
    var key: String
    var value: HackleValue
}

class RemoteConfigParameterDto: Codable {
    var id: Int64
    var key: String
    var type: String
    var identifierType: String
    var targetRules: [TargetRuleDto]
    var defaultValue: ValueDto

    class TargetRuleDto: Codable {
        var key: String
        var name: String
        var target: TargetDto
        var bucketId: Int64
        var value: ValueDto
    }

    class ValueDto: Codable {
        var id: Int64
        var value: HackleValue
    }
}

class DurationDto: Codable {
    var timeUnit: String
    var amount: Int64
}

class InAppMessageDto: Codable {
    var id: Int64
    var key: Int64
    var order: Int64?
    var timeUnit: String
    var startEpochTimeMillis: Int64?
    var endEpochTimeMillis: Int64?
    var timetable: TimetableDto?
    var status: String
    var eventTriggerRules: [EventTriggerRuleDto]
    var eventFrequencyCap: EventFrequencyCapDto?
    var eventTriggerDelay: EventTriggerDelayDto?
    var evaluateContext: EvaluateContextDto?
    var targetContext: TargetContextDto
    var messageContext: MessageContextDto

    class TimetableDto: Codable {
        var type: String
        var slots: [TimetableSlotDto]
    }

    class TimetableSlotDto: Codable {
        var dayOfWeek: String
        var startMillisInclusive: Int64
        var endMillisExclusive: Int64
    }

    class EventTriggerRuleDto: Codable {
        var eventKey: String
        var targets: [TargetDto]
    }

    class EventFrequencyCapDto: Codable {
        var identifiers: [IdentifierCapDto]
        var duration: DurationCapDto?
    }

    class IdentifierCapDto: Codable {
        var identifierType: String
        var countPerIdentifier: Int64
    }

    class DurationCapDto: Codable {
        var durationUnit: DurationDto
        var countPerDuration: Int64
    }

    class EventTriggerDelayDto: Codable {
        var type: String
        var afterCondition: AfterConditionDto?

        class AfterConditionDto: Codable {
            var duration: DurationDto
        }
    }

    class EvaluateContextDto: Codable {
        var atDeliverTime: Bool
    }

    class TargetContextDto: Codable {
        var targets: [TargetDto]
        var overrides: [UserOverrideDto]

        class UserOverrideDto: Codable {
            var identifierType: String
            var identifiers: [String]
        }
    }

    class MessageContextDto: Codable {
        var defaultLang: String
        var exposure: ExposureDto
        var platformTypes: [String]
        var orientations: [String]
        var messages: [MessageDto]

        class ExposureDto: Codable {
            var type: String
            var key: Int64?
        }

        class MessageDto: Codable {
            var variationKey: String?
            var lang: String
            var layout: LayoutDto
            var images: [ImageDto]
            var imageAutoScroll: ImageAutoScrollDto?
            var text: TextDto?
            var buttons: [ButtonDto]
            var closeButton: CloseButtonDto?
            var background: BackgroundDto
            var action: ActionDto?
            var outerButtons: [PositionalButtonDto]
            var innerButtons: [PositionalButtonDto]
            var html: HtmlDto?

            class LayoutDto: Codable {
                var displayType: String
                var layoutType: String
                var alignment: AlignmentDto?
            }

            class ImageDto: Codable {
                var orientation: String
                var imagePath: String
                var action: ActionDto?
            }

            class ImageAutoScrollDto: Codable {
                var interval: DurationDto
            }

            class TextDto: Codable {
                var title: TextAttributeDto
                var body: TextAttributeDto

                class TextAttributeDto: Codable {
                    var text: String
                    var style: StyleDto
                }

                class StyleDto: Codable {
                    var textColor: String
                }
            }

            class ButtonDto: Codable {
                var text: String
                var style: StyleDto
                var action: ActionDto

                class StyleDto: Codable {
                    var textColor: String
                    var bgColor: String
                    var borderColor: String
                }
            }

            class CloseButtonDto: Codable {
                var style: StyleDto
                var action: ActionDto

                class StyleDto: Codable {
                    var color: String
                }
            }

            class BackgroundDto: Codable {
                var color: String
            }

            class ExposureDto: Codable {
                var type: String
                var key: Int64?
            }

            class AlignmentDto: Codable {
                var vertical: String
                var horizontal: String
            }

            class PositionalButtonDto: Codable {
                var button: ButtonDto
                var alignment: AlignmentDto
            }

            class HtmlDto: Codable {
                var resourceType: String
                var text: String?
                var path: String?
            }
        }

        class ActionDto: Codable {
            var behavior: String
            var type: String
            var value: String?
        }
    }
}
