//
//  ExperimentEvaluator.swift
//  Hackle
//

import Foundation

protocol ExperimentEvaluator: LocalEvaluator where Request == ExperimentLocalEvaluateRequest, Response == ExperimentEvaluateResponse {
}
