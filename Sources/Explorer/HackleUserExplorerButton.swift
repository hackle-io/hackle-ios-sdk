//
//  HackleUserExplorerButton.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import UIKit


class HackleUserExplorerButton: UIView {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
    }

    func loadViewFromNib() {
        let bundle = Bundle(for: HackleUserExplorerButton.self)
        let view = bundle.loadNibNamed("HackleUserExplorerButton", owner: nil)?.first as! UIView
        view.frame = bounds
        addSubview(view)
    }
}
