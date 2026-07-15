import Foundation

// MARK: - 저장 (workspace_evaluation.json)

struct WorkspaceEvaluationContextDto: Codable {
    let key: [String: String] // identifiers
    let evaluation: WorkspaceEvaluationDto
    let fullEvaluatedAt: Int64
}

// MARK: - 응답

struct WorkspaceEvaluateResponseDto: Codable {
    let status: String // FULL, DELTA, NOT_MODIFIED
    let evaluation: WorkspaceEvaluationDto?
    let deleted: [EntityDto]

    private enum CodingKeys: String, CodingKey {
        case status, evaluation, deleted
    }
}

extension WorkspaceEvaluateResponseDto {
    // 서버가 deleted를 생략할 수 있어(특히 NOT_MODIFIED) 누락을 관용한다.
    // init을 extension에 두어 memberwise init을 보존한다(테스트 생성부에서 사용).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        evaluation = try container.decodeIfPresent(WorkspaceEvaluationDto.self, forKey: .evaluation)
        deleted = try container.decodeIfPresent([EntityDto].self, forKey: .deleted) ?? []
    }
}

struct WorkspaceEvaluationDto: Codable {
    let workspace: WorkspaceDto
    let results: [EvaluateResultDto]
    let metadata: WorkspaceEvaluationMetadataDto
}

struct WorkspaceEvaluationMetadataDto: Codable {
    let evaluatedAt: Int64
    let results: WorkspaceEvaluateResultsMetadataDto
    let user: HackleUserMetadataDto
    let config: WorkspaceConfigMetadataDto
}

struct WorkspaceEvaluateResultsMetadataDto: Codable {
    let hash: Int32
}

struct HackleUserMetadataDto: Codable {
    let hash: Int32
}

struct WorkspaceConfigMetadataDto: Codable {
    let modifiedAt: String
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
    let evaluateContext: InAppMessageDto.EvaluateContextDto

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
    let scope: String // ALL, SPECIFIC
    let policy: String // AUTO, FORCE_FULL
    let context: RemoteEvaluateContextDto
    let entities: [EvaluateEntityDto]
    let current: WorkspaceEvaluationMetadataDto?

    func toBody() -> [String: Any] {
        var body: [String: Any] = [
            "scope": scope,
            "policy": policy,
            "context": context.toBody(),
            "entities": entities.map { it in
                it.toBody()
            }
        ]
        if let current = current {
            body["current"] = current.toBody()
        }
        return body
    }
}

struct RemoteEvaluateContextDto {
    let platformType: String // ANDROID, IOS, WEB
    let user: HackleUserDto
    let operations: [String: [String: Any]]

    func toBody() -> [String: Any] {
        [
            "platformType": platformType,
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

struct EvaluateEntityDto {
    let type: String
    let id: Int64
    let hash: Int32?

    func toBody() -> [String: Any] {
        var body: [String: Any] = [
            "type": type,
            "id": id
        ]
        if let hash = hash {
            body["hash"] = hash
        }
        return body
    }
}

extension WorkspaceEvaluationMetadataDto {
    func toBody() -> [String: Any] {
        [
            "evaluatedAt": evaluatedAt,
            "results": ["hash": results.hash],
            "user": ["hash": user.hash],
            "config": ["modifiedAt": config.modifiedAt]
        ]
    }
}
