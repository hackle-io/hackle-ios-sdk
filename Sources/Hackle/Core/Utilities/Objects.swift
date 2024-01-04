import Foundation

class Objects {

    static func asStringOrNil(_ value: Any) -> String? {
        guard let value = value as? String else {
            return nil
        }
        return value
    }

    static func asIntOrNull(_ value: Any) -> Int64? {
        switch value {
        case is Int: return Int64(value as! Int)
        case is Int8: return Int64(value as! Int8)
        case is Int16: return Int64(value as! Int16)
        case is Int32: return Int64(value as! Int32)
        case is Int64: return Int64(value as! Int64)
        case is UInt: return Int64(value as! UInt)
        case is UInt8: return Int64(value as! UInt8)
        case is UInt16: return Int64(value as! UInt16)
        case is UInt32: return Int64(value as! UInt32)
        case is UInt64: return Int64(value as! UInt64)
        default: return nil
        }
    }

    static func asDoubleOrNil(_ value: Any) -> Double? {
        switch value {
        case is Double: return Double(value as! Double)
        case is Float: return Double(value as! Float)
        case is CLongDouble: return Double(value as! CLongDouble)
        default: return nil
        }
    }

    static func asBoolOrNil(_ value: Any) -> Bool? {
        guard let value = value as? Bool else {
            return nil
        }
        return value
    }
}

extension Optional {
    var orNil: String {
        guard let value = self else {
            return "nil"
        }
        return "\(value)"
    }
    
    func requireNotNil() throws -> Wrapped {
        if let wrapped = self {
            return wrapped
        } else {
            throw HackleError.error("Required value was nil.")
        }
    }
    
    func asIntOrNil() -> Int64? {
        if let value = self {
            return Objects.asIntOrNull(value)
        } else {
            return nil
        }
    }
}

extension Data {
    func hexString(separator: String = "") -> String {
        return self.map { String(format: "%.2hhx", $0) }
            .joined(separator: separator)
    }
}
