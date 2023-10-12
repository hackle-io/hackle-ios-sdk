//
// Created by yong on 2020/12/20.
//

import Foundation

class Json {

    static func isValid(_ obj: Any) -> Bool {
        JSONSerialization.isValidJSONObject(obj)
    }

    static func serialize(_ obj: Any) -> Data? {
        guard isValid(obj) else {
            return nil
        }

        var json: Data? = nil
        do {
            json = try JSONSerialization.data(withJSONObject: obj, options: [])
        } catch {
            Log.error("Fail to serialize obj")
        }

        return json
    }
}

extension String {
    func jsonObject() -> [String: Any]? {
        guard let data = data(using: .utf8, allowLossyConversion: false) else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}

extension Dictionary {
    func toJson() -> String? {
        guard  let data = Json.serialize(self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
