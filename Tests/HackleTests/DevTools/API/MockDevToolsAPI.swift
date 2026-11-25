import Foundation
import MockingKit
@testable import Hackle

class MockDevToolsAPI: Mock, DevToolsAPI {

    lazy var addExperimentOverridesMock = MockFunction(self, addExperimentOverrides)

    func addExperimentOverrides(experimentKey: Experiment.Key, request: OverrideRequest) {
        call(addExperimentOverridesMock, args: (experimentKey, request))
    }

    lazy var removeExperimentOverridesMock = MockFunction(self, removeExperimentOverrides)

    func removeExperimentOverrides(experimentKey: Experiment.Key, request: OverrideRequest) {
        call(removeExperimentOverridesMock, args: (experimentKey, request))
    }

    lazy var removeAllExperimentOverridesMock = MockFunction(self, removeAllExperimentOverrides)

    func removeAllExperimentOverrides(request: OverrideRequest) {
        call(removeAllExperimentOverridesMock, args: request)
    }

    lazy var addFeatureFlagOverridesMock = MockFunction(self, addFeatureFlagOverrides)

    func addFeatureFlagOverrides(experimentKey: Experiment.Key, request: OverrideRequest) {
        call(addFeatureFlagOverridesMock, args: (experimentKey, request))
    }

    lazy var removeFeatureFlagOverridesMock = MockFunction(self, removeFeatureFlagOverrides)

    func removeFeatureFlagOverrides(experimentKey: Experiment.Key, request: OverrideRequest) {
        call(removeFeatureFlagOverridesMock, args: (experimentKey, request))
    }

    lazy var removeAllFeatureFlagOverridesMock = MockFunction(self, removeAllFeatureFlagOverrides)

    func removeAllFeatureFlagOverrides(request: OverrideRequest) {
        call(removeAllFeatureFlagOverridesMock, args: request)
    }
}
