import Foundation

class OptOutManager: @unchecked Sendable {

    private let lock = ReadWriteLock(label: "io.hackle.OptOutManager.Lock")

    private var _isOptOutTracking: Bool

    var isOptOutTracking: Bool {
        lock.read { _isOptOutTracking }
    }

    init(configOptOutTracking: Bool) {
        _isOptOutTracking = configOptOutTracking
    }

    func setOptOutTracking(optOut: Bool) {
        lock.write {
            if optOut == _isOptOutTracking {
                return
            }
            _isOptOutTracking = optOut
            Log.info("OptOutTracking changed to \(optOut)")
        }
    }
}
