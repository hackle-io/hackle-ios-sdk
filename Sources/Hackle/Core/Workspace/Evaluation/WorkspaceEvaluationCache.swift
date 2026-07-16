import Foundation

protocol WorkspaceEvaluationCache {
    func get(key: WorkspaceEvaluationContext.Key) -> WorkspaceEvaluationContext?
    func put(context: WorkspaceEvaluationContext) -> [WorkspaceEvaluationContext] // put 후 전체 스냅샷(오래된 순)
    func latest() -> WorkspaceEvaluationContext?
    func restore(contexts: [WorkspaceEvaluationContext])
}

class LruWorkspaceEvaluationCache: WorkspaceEvaluationCache {

    private let capacity: Int
    private let lock = NSLock()
    private var entries = [WorkspaceEvaluationContext.Key: WorkspaceEvaluationContext]()
    private var order = [WorkspaceEvaluationContext.Key]()

    init(capacity: Int) {
        self.capacity = capacity
    }

    func get(key: WorkspaceEvaluationContext.Key) -> WorkspaceEvaluationContext? {
        lock.lock()
        defer { lock.unlock() }
        return entries[key]
    }

    func put(context: WorkspaceEvaluationContext) -> [WorkspaceEvaluationContext] {
        let lastEvaluatedAt = get(key: context.key)?.dto.metadata.evaluatedAt ?? Int64.min
        return safeLock.lock {
            if lastEvaluatedAt <= context.dto.metadata.evaluatedAt {
                remove(key: context.key)
                add(context: context)
                evict()
            }

            return order.compactMap { key in
                entries[key]
            }
        }
    }

    func latest() -> WorkspaceEvaluationContext? {
        lock.lock()
        defer { lock.unlock() }
        guard let key = order.last else {
            return nil
        }
        return entries[key]
    }

    func restore(contexts: [WorkspaceEvaluationContext]) {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
        order.removeAll()
        for context in contexts.suffix(capacity) {
            add(context: context)
        }
    }

    private func remove(key: WorkspaceEvaluationContext.Key) {
        entries.removeValue(forKey: key)
        order.removeAll { it in
            it == key
        }
    }

    private func add(context: WorkspaceEvaluationContext) {
        entries[context.key] = context
        order.append(context.key)
    }

    private func evict() {
        if order.count > capacity, let oldest = order.first {
            remove(key: oldest)
        }
    }
}
