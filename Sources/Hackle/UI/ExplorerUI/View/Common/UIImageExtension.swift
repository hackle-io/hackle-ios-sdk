//
//  UIImageExtension.swift
//  Hackle
//

import UIKit

extension UIImage {
    static func hackle(named name: String) -> UIImage? {
        guard let image = UIImage(named: name, in: HackleInternalResources.bundle, compatibleWith: nil) else {
            Log.debug("Image not found: \(name)")
            return nil
        }
        return image
    }
}
