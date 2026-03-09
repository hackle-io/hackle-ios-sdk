import Foundation

class OptOutManager {

    private let keyValueRepository: KeyValueRepository
    private let lock = ReadWriteLock(label: "io.hackle.OptOutManager.Lock")

    private var _isOptOutTracking: Bool = false

    var isOptOutTracking: Bool {
        lock.read { _isOptOutTracking }
    }

    init(keyValueRepository: KeyValueRepository, configOptOutTracking: Bool) {
        self.keyValueRepository = keyValueRepository

        let savedOptOut = keyValueRepository.getString(key: OptOutManager.OPT_OUT_KEY)
            .flatMap { Bool($0) } ?? false
        _isOptOutTracking = configOptOutTracking || savedOptOut
        save(optOut: _isOptOutTracking)
    }

    func setOptOutTracking(optOut: Bool) {
        lock.write {
            if optOut == _isOptOutTracking {
                return
            }
            _isOptOutTracking = optOut
            save(optOut: optOut)
            Log.info("OptOutTracking changed to \(optOut)")
        }
    }

    private func save(optOut: Bool) {
        keyValueRepository.putString(key: OptOutManager.OPT_OUT_KEY, value: String(optOut))
    }

    private static let OPT_OUT_KEY = "opt_out_tracking"
}
