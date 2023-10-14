//
//  UserCohortFetcher.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation

protocol UserCohortFetcher {
    func fetch(user: User, completion: @escaping (UserCohorts?, Error?) -> ())
}

class DefaultUserCohortFetcher : UserCohortFetcher {
    func fetch(user: User, completion: @escaping (UserCohorts?, Error?) -> ()) {
        Data().base64EncodedData(options: .url)
    }
}

class EmptyUserCohortFetcher: UserCohortFetcher {
    func fetch(user: User, completion: @escaping (UserCohorts?, Error?) -> ()) {
        Log.debug("UserCohorts fetched")
        completion(UserCohorts.empty(), nil)
    }
}
