//
//  RemoteConfigEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

protocol RemoteConfigEvaluator: LocalEvaluator where Request == RemoteConfigLocalEvaluateRequest, Response == RemoteConfigEvaluateResponse {
}
