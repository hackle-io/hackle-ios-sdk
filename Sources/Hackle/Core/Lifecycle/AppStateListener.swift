//
// Created by yong on 2020/12/11.
//

import Foundation

protocol AppStateListener {
    func onState(state: ApplicationState, timestamp: Date)
}
