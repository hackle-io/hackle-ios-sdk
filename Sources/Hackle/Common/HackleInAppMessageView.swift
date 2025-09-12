//
//  HackleInAppMessageView.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

/// Protocol for controlling in-app message view presentation.
@objc public protocol HackleInAppMessageView {
    /// Dismisses the in-app message view.
    func dismiss()
}
