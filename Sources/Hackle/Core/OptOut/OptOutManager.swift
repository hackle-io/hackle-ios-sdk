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
        lock.write {
            if _isOptOutTracking == optOut { return }
            _isOptOutTracking = optOut
        }
        Log.info("OptOutTracking changed to \(optOut)")
        for listener in listeners {
            listener.onOptOutChanged(current: optOut)
        }
    }
}
