import Foundation

class Evaluators {

    static func context() -> EvaluatorContext {
        DefaultContext()
    }

    private class DefaultContext: EvaluatorContext {
        private var _stack: [EvaluateRequest] = []
        private var _references: [Evaluation] = []
        private var _values: [Any] = []
        private var _properties = PropertiesBuilder()

        var stack: [EvaluateRequest] { _stack }
        var references: [Evaluation] { _references }
        var properties: [String: Any] { _properties.build() }

        func contains(_ request: EvaluateRequest) -> Bool {
            _stack.contains { $0.entity.entityKey == request.entity.entityKey }
        }
        func add(_ request: EvaluateRequest) { _stack.append(request) }
        func remove(_ request: EvaluateRequest) {
            _stack.removeAll { $0.entity.entityKey == request.entity.entityKey }
        }

        func get(_ entity: Entity) -> Evaluation? {
            _references.first { $0.entity.entityKey == entity.entityKey }
        }
        func add(_ evaluation: Evaluation) { _references.append(evaluation) }

        func get<T>(_ type: T.Type) -> T? { _values.first { $0 is T } as? T }
        func set(_ value: Any) { _values.append(value) }

        func setProperty(_ key: String, _ value: Any?) { _properties.add(key, value) }
    }
}
