import Foundation

protocol Evaluator {
    func evaluate<R: EvaluateResponse>(request: EvaluateRequest, context: EvaluatorContext) throws -> R
    func record(request: EvaluateRequest, response: EvaluateResponse)
}

protocol EvaluatorContext {
    var stack: [EvaluateRequest] { get }
    var references: [Evaluation] { get }

    func contains(_ request: EvaluateRequest) -> Bool
    func add(_ request: EvaluateRequest)
    func remove(_ request: EvaluateRequest)

    func get(_ entity: Entity) -> Evaluation?
    func add(_ evaluation: Evaluation)

    func get<T>(_ type: T.Type) -> T?
    func set(_ value: Any)

    var properties: [String: Any] { get }
    func setProperty(_ key: String, _ value: Any?)
}
