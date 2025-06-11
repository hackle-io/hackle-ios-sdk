//
// Created by yong on 2020/12/11.
//

import Foundation

protocol WorkspaceFetcher {
    var lastModified: String? { get }
    func fetch() -> Workspace?
}
