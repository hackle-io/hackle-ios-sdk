//
//  InAppMessagePresenter.swift
//  Hackle
//
//  Created by yong on 2023/06/07.
//

import Foundation

protocol InAppMessagePresenter {
    /// 메시지 표시를 시도하고 실제 노출 여부를 반환한다. 노출되지 않은 메시지는 impression으로 기록되지 않아야 한다.
    func present(context: InAppMessagePresentationContext) async -> Bool
}
