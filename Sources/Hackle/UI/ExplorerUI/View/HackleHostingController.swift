//
//  HackleHostingController.swift
//  Hackle
//

import SwiftUI

@MainActor
final class HackleHostingController<Content: View>: UIHostingController<Content>, HackleViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
    }
}
