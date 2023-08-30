//
//  HackleExperiment.swift
//  Hackle
//
//  Created by yong on 2023/08/30.
//

import Foundation

@objc public final class HackleExperiment: NSObject {

    @objc public let key: Int64
    @objc public let version: Int

    init(key: Int64, version: Int) {
        self.key = key
        self.version = version
        super.init()
    }

    static func from(experiment: Experiment) -> HackleExperiment {
        HackleExperiment(key: experiment.key, version: experiment.version)
    }
}

extension Experiment {
    func toPublic() -> HackleExperiment {
        HackleExperiment.from(experiment: self)
    }
}
