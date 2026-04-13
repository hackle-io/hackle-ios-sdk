//
//  HackleUserExplorerButton.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import UIKit
import SwiftUI


class HackleUserExplorerButton: UIView {

    private var hostingController: UIHostingController<ExplorerButtonContent>?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        let hosting = UIHostingController(rootView: ExplorerButtonContent())
        hosting.view.frame = bounds
        hosting.view.backgroundColor = .clear
        addSubview(hosting.view)
        hostingController = hosting
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        hostingController?.view.frame = bounds
    }
}
