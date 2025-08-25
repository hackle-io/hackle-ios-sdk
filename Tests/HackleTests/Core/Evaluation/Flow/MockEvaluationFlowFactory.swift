//
//  MockEvaluationFlowFactory.swift
//  HackleTests
//
//  Created by yong on 2023/04/20.
//

import Foundation
@testable import Hackle

class MockEvaluationFlowFactory: EvaluationFlowFactory {

    var experimentFlow: EvaluationFlow<ExperimentRequest, ExperimentEvaluation>
    var inAppMessageFlow: EvaluationFlow<InAppMessageEligibilityRequest, InAppMessageEligibilityEvaluation>

    init(
        experimentFlow: EvaluationFlow<ExperimentRequest, ExperimentEvaluation> = EvaluationFlow<ExperimentRequest, ExperimentEvaluation>.end(),
        inAppMessageFlow: EvaluationFlow<InAppMessageEligibilityRequest, InAppMessageEligibilityEvaluation> = EvaluationFlow<InAppMessageEligibilityRequest, InAppMessageEligibilityEvaluation>.end()
    ) {
        self.experimentFlow = experimentFlow
        self.inAppMessageFlow = inAppMessageFlow
    }

    func getExperimentFlow(experimentType: ExperimentType) -> EvaluationFlow<ExperimentRequest, ExperimentEvaluation> {
        experimentFlow
    }

    func getInAppMessageFlow() -> EvaluationFlow<InAppMessageEligibilityRequest, InAppMessageEligibilityEvaluation> {
        inAppMessageFlow
    }
}