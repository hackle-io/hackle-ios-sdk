import Foundation

class OptOutManager: @unchecked Sendable {

    private let lock = ReadWriteLock(label: "io.hackle.OptOutManager.Lock")

    private var _isOptOutTracking: Bool
    private var listeners: [OptOutListener] = []

    var isOptOutTracking: Bool {
        lock.read { _isOptOutTracking }
    }

    init(configOptOutTracking: Bool) {
        _isOptOutTracking = configOptOutTracking
    }

    func addListener(listener: OptOutListener) {
        listeners.append(listener)
    }

    func setOptOutTracking(optOut: Bool) {
        let previous: Bool? = lock.write {
            if optOut == _isOptOutTracking { return nil }
            let prev = _isOptOutTracking
            _isOptOutTracking = optOut
            return prev
        }
        guard let previous else { return }
        Log.info("OptOutTracking changed to \(optOut)")
        for listener in listeners {
            listener.onOptOutChanged(previous: previous, current: optOut)
        }
    }
}
