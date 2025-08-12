//
//  HackleBridgeParameters.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

typealias HackleBridgeParameters = [String: Any?]

extension HackleBridgeParameters {
    func userAsDictionary() -> [String: Any]? {
        self["user"] as? [String: Any]
    }
    
    func user() -> User? {
        if let id = self["user"] as? String {
            return Hackle.user(id: id)
        }
        
        if let data = userAsDictionary(),
           let user = User.from(dto: data) {
            return user
        }
        
        return nil
    }
}
