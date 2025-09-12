//
//  HackleUserExplorerButton.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import UIKit


class HackleUserExplorerButton: UIView {

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "hackle_logo.png", in: HackleInternalResources.bundle, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor.clear
        
        addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 40),
            logoImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
}
