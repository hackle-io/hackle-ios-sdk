import Foundation

protocol WorkspaceEvaluationCache {
    func get(key: WorkspaceEvaluationContext.Key) -> WorkspaceEvaluationContext?
    func put(record: WorkspaceEvaluationContext) -> [WorkspaceEvaluationContext] // put 후 전체 스냅샷(오래된 순)
    func latest() -> WorkspaceEvaluationContext?
    func restore(records: [WorkspaceEvaluationContext])
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

    func put(record: WorkspaceEvaluationContext) -> [WorkspaceEvaluationContext] {
        lock.lock()
        defer { lock.unlock() }
        remove(key: record.key)
        add(record: record)
        evict()
        return order.compactMap { key in
            entries[key]
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

    func restore(records: [WorkspaceEvaluationContext]) {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
        order.removeAll()
        for record in records.suffix(capacity) {
            add(record: record)
        }
    }

    private func remove(key: WorkspaceEvaluationContext.Key) {
        entries.removeValue(forKey: key)
        order.removeAll { it in
            it == key
        }
    }

    private func add(record: WorkspaceEvaluationContext) {
        entries[record.key] = record
        order.append(record.key)
    }

    private func evict() {
        if order.count > capacity, let oldest = order.first {
            remove(key: oldest)
        }
    }
}
