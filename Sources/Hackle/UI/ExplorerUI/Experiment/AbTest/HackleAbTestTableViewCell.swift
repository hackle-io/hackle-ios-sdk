//
//  HackleAbTestTableViewCell.swift
//  Hackle
//
//  Created by yong on 2023/03/28.
//

import UIKit


class HackleAbTestTableViewCell: UITableViewCell {

    @IBOutlet weak var experimentKeyLabel: UILabel!
    @IBOutlet weak var experimentDescLabel: UILabel!
    @IBOutlet weak var variationButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    private var item: HackleAbTestItem!
    private var overrideSetListener: OnOverrideSetListener!
    private var overrideResetListener: OnOverrideResetListener!
    private var superView: UIViewController!
    private var alertController: UIAlertController!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
    }

    func bind(
        item: HackleAbTestItem,
        superView: UIViewController,
        overrideSetListener: OnOverrideSetListener,
        overrideResetListener: OnOverrideResetListener
    ) {
        self.item = item
        self.superView = superView
        self.overrideSetListener = overrideSetListener
        self.overrideResetListener = overrideResetListener

        experimentKeyLabel.text = item.keyLabel
        experimentKeyLabel.lineBreakMode = .byTruncatingTail
        experimentDescLabel.text = item.descLabel
        resetButton.isEnabled = item.overriddenVariation != nil
        initVariationButton()
    }

    private func initVariationButton() {
        variationButton.setTitle(item.decision.variation, for: .normal)
        variationButton.isEnabled = DecisionReasons.isOverridable(reason: item.decision.reason)
        alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        for variation in item.experiment.variations {
            alertController.addAction(
                UIAlertAction(title: variation.key, style: .default) { _ in
                    self.onOverrideSelected(variation: variation)
                }
            )
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    }

    @IBAction func variationButtonTapped(_ sender: UIButton) {
        superView.present(alertController, animated: true)
    }

    @IBAction func resetButtonTapped(_ sender: UIButton) {
        overrideResetListener.onOverrideReset(experiment: item.experiment)
    }

    private func onOverrideSelected(variation: Variation) {
        guard let variation = item.experiment.getVariationOrNil(variationId: variation.id) else {
            return
        }
        overrideSetListener.onOverrideSet(experiment: item.experiment, variation: variation)
        variationButton.setTitle(variation.key, for: .normal)
    }
}


private extension HackleAbTestItem {
    var keyLabel: String {
        "[\(experiment.key)] \(experiment.name ?? "")"
    }

    var descLabel: String {
        [
            "V\(experiment.version)",
            experiment.status.rawValue,
            experiment.variations.map { it in
                    it.key
                }
                .joined(separator: "/")
        ]
            .joined(separator: " | ")
    }
}
