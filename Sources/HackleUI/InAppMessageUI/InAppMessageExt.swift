//
//  InAppMessageExt.swift
//  Hackle
//
//  Created by yong on 2023/06/16.
//

import Foundation
import UIKit

extension InAppMessage.Orientation {

    init(size: CGSize) {
        if size.height >= size.width {
            self = .vertical
            return
        }
        self = .horizontal
    }

    func supports(_ orientation: UIInterfaceOrientation) -> Bool {
        switch self {
        case .vertical:
            return orientation.isPortrait
        case .horizontal:
            return orientation.isLandscape
        }
    }
}

extension InAppMessage.Message {
    var backgroundColor: UIColor {
        UIColor(hex: background.color) ?? .white
    }


    func image(orientation: InAppMessage.Orientation) -> Image? {
        images.first {
            $0.orientation == orientation
        }
    }

    // Orientation

    var supportedOrientations: [InAppMessage.Orientation] {
        images.map {
            $0.orientation
        }
    }

    func supports(orientation: UIInterfaceOrientation) -> Bool {
        supportedOrientations.contains {
            $0.supports(orientation)
        }
    }

    func supports(orientation: InAppMessage.Orientation) -> Bool {
        supportedOrientations.contains(orientation)
    }
}

extension InAppMessage.Message.Button {
    var textColor: UIColor {
        UIColor(hex: style.textColor) ?? .black
    }

    var backgroundColor: UIColor {
        UIColor(hex: style.bgColor) ?? .white
    }

    var borderColor: UIColor {
        UIColor(hex: style.borderColor) ?? .white
    }

    var trackProperties: [String: Any] {
        PropertiesBuilder()
            .add("button_text", text)
            .build()
    }
}

extension InAppMessage.Message.Text.Attribute {

    var color: UIColor {
        UIColor(hex: style.textColor) ?? .black
    }

    func attributed(with attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        NSAttributedString(string: text, attributes: attributes)
    }

    func attributed(font: UIFont, color: UIColor) -> NSAttributedString {
        attributed(
            with: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: color
            ]
        )
    }
}
