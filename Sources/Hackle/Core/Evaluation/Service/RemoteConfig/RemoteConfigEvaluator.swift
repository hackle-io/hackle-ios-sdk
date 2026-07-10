//
//  RemoteConfigEvaluator.swift
//  Hackle
//

import Foundation

protocol RemoteConfigEvaluator: ContextualEvaluator where Request: RemoteConfigEvaluateRequest, Response == RemoteConfigEvaluateResponse {
}
