import Foundation

class Objects {

    static func asIntOrNull(_ value: Any) -> Int64? {
        if isBoolType(value) {
            return nil
        }

        switch value {
        case is Int: return Int64(value as! Int)
        case is Int8: return Int64(value as! Int8)
        case is Int16: return Int64(value as! Int16)
        case is Int32: return Int64(value as! Int32)
        case is Int64: return Int64(value as! Int64)
        case is UInt: return Int64(exactly: value as! UInt)
        case is UInt8: return Int64(value as! UInt8)
        case is UInt16: return Int64(value as! UInt16)
        case is UInt32: return Int64(value as! UInt32)
        case is UInt64: return Int64(exactly: value as! UInt64)
        default: return nil
        }
    }

    static func isBoolType(_ value: Any) -> Bool {
        let isBool = value is Bool
        let isNSNumberType = isNSNumberType(value)
        return isBool && !isNSNumberType
    }

    static func isNSNumberType(_ value: Any) -> Bool {
        let valueType = type(of: value)
        let nsNumberType = type(of: NSNumber(value: 0))
        return valueType == nsNumberType
    }
}

extension Optional {
    func asIntOrNil() -> Int64? {
        if let value = self {
            return Objects.asIntOrNull(value)
        } else {
            return nil
        }
    }
}
