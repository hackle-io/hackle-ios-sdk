//
//  HackleUserExplorerButton.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import UIKit


class HackleUserExplorerButton: UIView {

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "hackle_logo.png", in: HackleInternalResources.bundle, compatibleWith: nil)
        return iv
    }()

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
        imageView.frame = bounds
        addSubview(imageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}
