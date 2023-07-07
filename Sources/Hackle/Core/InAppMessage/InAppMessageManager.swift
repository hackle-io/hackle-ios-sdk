//
//  InAppMessageManager.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation

class InAppMessageManager: UserEventListener {

    private let determiner: InAppMessageDeterminer
    private let presenter: InAppMessagePresenter

    init(determiner: InAppMessageDeterminer, presenter: InAppMessagePresenter) {
        self.determiner = determiner
        self.presenter = presenter
    }

    func onEvent(event: UserEvent) {
        guard let context = determine(event: event) else {
            return
        }

        presenter.present(context: context)
    }

    private func determine(event: UserEvent) -> InAppMessageContext? {
        do {
            return try determiner.determineOrNull(event: event)
        } catch {
            Log.error("Failed to determine InAppMessage: \(error)")
            return nil
        }
    }
}
