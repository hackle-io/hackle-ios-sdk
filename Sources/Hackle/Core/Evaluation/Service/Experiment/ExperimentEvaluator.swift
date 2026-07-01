//
//  ExperimentEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

protocol ExperimentEvaluator: LocalEvaluator where Request == ExperimentLocalEvaluateRequest, Response == ExperimentEvaluateResponse {
}
