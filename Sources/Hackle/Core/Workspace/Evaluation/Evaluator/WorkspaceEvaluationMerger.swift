import Foundation

enum WorkspaceEvaluationMerger {

    private struct Key: Hashable {
        let type: String
        let id: Int64
    }

    static func merge(evaluation: WorkspaceEvaluationDto, response: WorkspaceEvaluateResponseDto) throws -> WorkspaceEvaluationDto {
        guard let responseEvaluation = response.evaluation else {
            throw HackleError.error("evaluation")
        }

        var order = [Key]()
        var merged = [Key: EvaluateResultDto]()

        for result in evaluation.results {
            let key = Key(type: result.type, id: result.id)
            if merged[key] == nil {
                order.append(key)
            }
            merged[key] = result
        }

        for result in responseEvaluation.results {
            let key = Key(type: result.type, id: result.id)
            if merged[key] == nil {
                order.append(key)
            }
            merged[key] = result
        }

        for entity in response.deleted {
            let key = Key(type: entity.type, id: entity.id)
            if merged.removeValue(forKey: key) != nil {
                order.removeAll { it in
                    it == key
                }
            }
        }

        return WorkspaceEvaluationDto(
            workspace: evaluation.workspace,
            results: order.compactMap { key in
                merged[key]
            },
            metadata: responseEvaluation.metadata
        )
    }

    // 서버 metadata hash는 32비트 정수이므로 반드시 Int32 랩핑 산술로 계산한다.
    // Swift Int(64비트)로 계산하면 오버플로 시 불일치 → 불필요한 FORCE_FULL 재요청 루프.
    static func hash(results: [EvaluateResultDto]) -> Int32 {
        var acc: Int32 = 1
        for h in results.map({ it in it.hash }).sorted() {
            acc = acc &* 31 &+ h
        }
        return acc
    }
}
