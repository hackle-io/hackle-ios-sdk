//
//  RemoteConfigEvaluator.swift
//  Hackle
//

import Foundation

protocol RemoteConfigEvaluator: LocalEvaluator where Request == RemoteConfigLocalEvaluateRequest, Response == RemoteConfigEvaluateResponse {
}
