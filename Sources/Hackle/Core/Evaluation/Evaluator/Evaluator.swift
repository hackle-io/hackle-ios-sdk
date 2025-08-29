import Foundation

protocol Evaluator {
    func evaluate<Evaluation>(request: EvaluatorRequest, context: EvaluatorContext) throws -> Evaluation where Evaluation: EvaluatorEvaluation
}

enum EvaluatorType: String {
    case experiment = "EXPERIMENT"
    case remoteConfig = "REMOTE_CONFIG"
    case inAppMessage = "IN_APP_MESSAGE"
}

struct EvaluatorKey: Equatable {
    let type: EvaluatorType
    let id: Int64

    public static func ==(lhs: EvaluatorKey, rhs: EvaluatorKey) -> Bool {
        lhs.type == rhs.type && lhs.id == rhs.id
    }
}

protocol EvaluatorRequest {
    var key: EvaluatorKey { get }
    var workspace: Workspace { get }
    var user: HackleUser { get }
}

protocol EvaluatorEventRequest: EvaluatorRequest {
    var event: UserEvent { get }
}

protocol EvaluatorEvaluation {
    var reason: String { get }
    var targetEvaluations: [EvaluatorEvaluation] { get }
}

protocol EvaluatorContext {
    var stack: [EvaluatorRequest] { get }
    var targetEvaluations: [EvaluatorEvaluation] { get }
    var properties: [String: Any] { get }

    func contains(_ request: EvaluatorRequest) -> Bool
    func add(_ request: EvaluatorRequest)
    func remove(_ request: EvaluatorRequest)

    func get(_ experiment: Experiment) -> EvaluatorEvaluation?
    func add(_ evaluation: EvaluatorEvaluation)

    func setProperty(_ key: String, _ value: Any?)

    func get<T>(_ type: T.Type) -> T?
    func set(_ value: Any)
}

class Evaluators {

    static func context() -> EvaluatorContext {
        DefaultContext()
    }

    private class DefaultContext: EvaluatorContext {
        private var _stack: [EvaluatorRequest]
        private var _targetEvaluations: [EvaluatorEvaluation]
        private var _properties: PropertiesBuilder
        private var _values: [Any]

        init() {
            _stack = []
            _targetEvaluations = []
            _properties = PropertiesBuilder()
            _values = []
        }

        var stack: [EvaluatorRequest] {
            get {
                _stack
            }
        }

        var targetEvaluations: [EvaluatorEvaluation] {
            get {
                _targetEvaluations
            }
        }
        var properties: [String: Any] {
            get {
                _properties.build()
            }
        }

        func contains(_ request: EvaluatorRequest) -> Bool {
            _stack.contains { it in
                it.key == request.key
            }
        }

        func add(_ request: EvaluatorRequest) {
            _stack.append(request)
        }

        func remove(_ request: EvaluatorRequest) {
            _stack.removeAll { it in
                it.key == request.key
            }
        }

        func get(_ experiment: Experiment) -> EvaluatorEvaluation? {
            _targetEvaluations.lazy
                .compactMap { it in
                    it as? ExperimentEvaluation
                }
                .first { it in
                    it.experiment.id == experiment.id
                }
        }

        func add(_ evaluation: EvaluatorEvaluation) {
            _targetEvaluations.append(evaluation)
        }

        func setProperty(_ key: String, _ value: Any?) {
            _properties.add(key, value)
        }

        func get<T>(_ type: T.Type) -> T? {
            return _values.first { value in
                value is T
            } as? T
        }

        func set(_ value: Any) {
            _values.append(value)
        }
    }
}
