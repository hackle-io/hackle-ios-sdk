//
// Created by yong on 2020/12/11.
//

import Foundation

protocol AppStateChangeListener {
    func onChanged(state: AppState, timestamp: Date)
}
