import Foundation

class Objects {

    static func asStringOrNil(_ value: Any) -> String? {
        guard let value = value as? String else {
            return nil
        }
        return value
    }

    static func asDoubleOrNil(_ value: Any) -> Double? {
        switch value {
        case is Int: return Double(value as! Int)
        case is Int8: return Double(value as! Int8)
        case is Int16: return Double(value as! Int16)
        case is Int32: return Double(value as! Int32)
        case is Int64: return Double(value as! Int64)
        case is UInt: return Double(value as! UInt)
        case is UInt8: return Double(value as! UInt8)
        case is UInt16: return Double(value as! UInt16)
        case is UInt32: return Double(value as! UInt32)
        case is UInt64: return Double(value as! UInt64)
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
