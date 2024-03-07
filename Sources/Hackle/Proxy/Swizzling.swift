import Foundation

class Swizzling {
    static func injectSelector(
        targetClass: AnyClass,
        targetSelector: Selector,
        proxyClass: AnyClass,
        proxySelector: Selector
    ) -> Bool {
        guard let proxyMethod = class_getInstanceMethod(proxyClass, proxySelector) else {
            return false
        }
        
        let proxyMethodImpl = method_getImplementation(proxyMethod)
        let proxyTypeEncoding = method_getTypeEncoding(proxyMethod)
        
        if let targetMethod = class_getInstanceMethod(targetClass, targetSelector) {
            method_exchangeImplementations(targetMethod, proxyMethod)
        } else {
            class_addMethod(targetClass, targetSelector, proxyMethodImpl, proxyTypeEncoding)
        }
        return true
    }
}
