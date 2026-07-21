import Foundation

// MARK: - 저장 (workspace_evaluation.json)

struct WorkspaceEvaluationContextDto: Codable {
    let key: [String: String] // identifiers
    let evaluation: WorkspaceEvaluationDto
    let fullEvaluatedAt: Int64
}

// MARK: - 응답

struct WorkspaceEvaluateResponseDto: Codable {
    let status: String // FULL, DELTA
    let full: WorkspaceEvaluationDto?
    let delta: WorkspaceEvaluationDeltaDto?
}

struct WorkspaceEvaluationDto: Codable {
    let workspace: WorkspaceDto
    let metadata: WorkspaceEvaluationMetadataDto
    let results: [EvaluateResultDto]
}

struct WorkspaceEvaluationDeltaDto: Codable {
    let metadata: WorkspaceEvaluationMetadataDto
    let changed: [EvaluateResultDto]
    let deleted: [EntityDto]
}

protocol EvaluationMetadataDto {
    var evaluatedAt: Int64 { get }
    var config: WorkspaceConfigMetadataDto { get }
}

struct WorkspaceEvaluationMetadataDto: Codable, EvaluationMetadataDto {
    let hash: Int32
    let evaluatedAt: Int64
    let user: HackleUserMetadataDto
    let config: WorkspaceConfigMetadataDto
}

struct HackleUserMetadataDto: Codable {
    let hash: Int32
}

struct WorkspaceConfigMetadataDto: Codable {
    let modifiedAt: String
}

struct EntityEvaluateResponseDto: Codable {
    let evaluation: EntityEvaluationDto
}

struct EntityEvaluationDto: Codable {
    let workspace: WorkspaceDto
    let metadata: EntityEvaluationMetadataDto
    let results: [EvaluateResultDto]
}

struct EntityEvaluationMetadataDto: Codable, EvaluationMetadataDto {
    let evaluatedAt: Int64
    let config: WorkspaceConfigMetadataDto
}

struct EvaluateResultDto: Codable {
    let type: String
    let id: Int64
    let hash: Int32

    let experiment: ExperimentEvaluateResultDto?
    let featureFlag: ExperimentEvaluateResultDto?
    let remoteConfig: RemoteConfigParameterEvaluateResultDto?
    let inAppMessage: InAppMessageEligibilityEvaluateResultDto?
}

struct ExperimentEvaluateResultDto: Codable {
    let id: Int64
    let key: Int64
    let order: Int64
    let version: Int
    let executionVersion: Int

    let variation: VariationDto
    let config: ParameterConfigurationDto?

    let reason: String
    let references: [EntityDto]
}

struct RemoteConfigParameterEvaluateResultDto: Codable {
    let id: Int64
    let key: String
    let valueType: String
    let value: RemoteConfigParameterDto.ValueDto?
    let reason: String
    let references: [EntityDto]
}

struct InAppMessageEligibilityEvaluateResultDto: Codable {
    let id: Int64
    let key: Int64
    let order: Int64

    // Period
    let period: InAppMessageDto.PeriodDto?
    let timetable: InAppMessageDto.TimetableDto?

    // EventTrigger
    let eventTriggerRules: [InAppMessageDto.EventTriggerRuleDto]
    let eventFrequencyCap: InAppMessageDto.EventFrequencyCapDto?
    let eventTriggerDelay: InAppMessageDto.EventTriggerDelayDto?

    // EvaluateContext
    let evaluateContext: InAppMessageDto.EvaluateContextDto?

    // MessageContext
    let messageContext: InAppMessageDto.MessageContextDto

    // Result
    let isEligible: Bool
    let layout: InAppMessageLayoutEvaluateResultDto
    let reason: String
    let references: [EntityDto]
}

struct InAppMessageLayoutEvaluateResultDto: Codable {
    let message: InAppMessageDto.MessageContextDto.MessageDto
    let reason: String
    let references: [EntityDto]
}

struct EntityDto: Codable {
    let type: String
    let id: Int64
}

extension InAppMessageDto {
    // evaluate API 전용 period 형태 (config의 timeUnit/startEpochTimeMillis 플랫 구조와 다름)
    struct PeriodDto: Codable {
        let type: String // IMMEDIATE, CUSTOM
        let startMillisInclusive: Int64?
        let endMillisExclusive: Int64?
    }
}

// MARK: - 요청 (userProperties/operations가 [String: Any]라 Codable 불가 → dictionary 직렬화)

struct WorkspaceEvaluateRequestDto {
    let policy: String // AUTO, FORCE_FULL
    let context: RemoteEvaluateContextDto
    let base: BaseEvaluationDto?

    func toBody() -> [String: Any] {
        var body: [String: Any] = [
            "policy": policy,
            "context": context.toBody()
        ]
        if let base = base {
            body["base"] = base.toBody()
        }
        return body
    }
}

struct BaseEvaluationDto {
    let fullEvaluatedAt: Int64
    let metadata: WorkspaceEvaluationMetadataDto
    let entities: [EvaluateEntityDto]

    func toBody() -> [String: Any] {
        [
            "fullEvaluatedAt": fullEvaluatedAt,
            "metadata": metadata.toBody(),
            "entities": entities.map { it in
                it.toBody()
            }
        ]
    }
}

struct EvaluateEntityDto {
    let type: String
    let id: Int64
    let hash: Int32

    func toBody() -> [String: Any] {
        [
            "type": type,
            "id": id,
            "hash": hash
        ]
    }
}

struct EntityEvaluateRequestDto {
    let context: RemoteEvaluateContextDto
    let entities: [EntityDto]

    func toBody() -> [String: Any] {
        [
            "context": context.toBody(),
            "entities": entities.map { it in
                ["type": it.type, "id": it.id] as [String: Any]
            }
        ]
    }
}

struct RemoteEvaluateContextDto {
    let user: HackleUserDto
    let operations: [String: [String: Any]]

    func toBody() -> [String: Any] {
        [
            "user": user.toBody(),
            "operations": operations
        ]
    }
}

struct HackleUserDto {
    let identifiers: [String: String]
    let userProperties: [String: Any]
    let hackleProperties: [String: Any]

    func toBody() -> [String: Any] {
        [
            "identifiers": identifiers,
            "userProperties": userProperties,
            "hackleProperties": hackleProperties
        ]
    }
}

extension WorkspaceEvaluationMetadataDto {
    func toBody() -> [String: Any] {
        [
            "hash": hash,
            "evaluatedAt": evaluatedAt,
            "user": ["hash": user.hash],
            "config": ["modifiedAt": config.modifiedAt]
        ]
    }
}
