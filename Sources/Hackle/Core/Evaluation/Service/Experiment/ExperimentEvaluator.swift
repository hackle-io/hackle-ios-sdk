//
//  ExperimentEvaluator.swift
//  Hackle
//

import Foundation

protocol ExperimentEvaluator: ContextualEvaluator where Request: ExperimentEvaluateRequest, Response == ExperimentEvaluateResponse {
}
