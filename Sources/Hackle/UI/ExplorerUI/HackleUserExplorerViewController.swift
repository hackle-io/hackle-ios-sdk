//
//  HackleUserExplorerViewController.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import UIKit


class HackleUserExplorerViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    @IBOutlet weak var dismissButton: UIImageView!

    @IBOutlet weak var defaultIdLabel: UILabel!
    @IBOutlet weak var deviceIdLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var pushTokenLabel: UILabel!

    @IBOutlet weak var defaultIdCopyButton: UIButton!
    @IBOutlet weak var deviceIdCopyButton: UIButton!
    @IBOutlet weak var userIdCopyButton: UIButton!
    @IBOutlet weak var pushTokenCopyButton: UIButton!
    @IBOutlet weak var copiedLabel: UILabel!

    @IBOutlet weak var abTestButton: UIButton!
    @IBOutlet weak var featureFlagButton: UIButton!

    @IBOutlet weak var experimentPageView: UIView!
    private var experimentPageViewController: UIPageViewController!
    private var abTestViewController: HackleAbTestViewController!
    private var featureFlagViewController: HackleFeatureFlagViewController!

    private var explorer: HackleUserExplorer!

    override func viewDidLoad() {
        super.viewDidLoad()
        explorer = Hackle.app()!.userExplorer
        initDismissButton()
        initUser()
        initPageView()
    }

    private func initDismissButton() {
        dismissButton.isUserInteractionEnabled = true
        dismissButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSelf)))
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    private func initUser() {
        let user = explorer.currentUser()
        if let defaultId = user.id {
            defaultIdLabel.text = defaultId
            defaultIdCopyButton.isEnabled = true
        }

        if let deviceId = user.deviceId {
            deviceIdLabel.text = deviceId
            deviceIdCopyButton.isEnabled = true
        }

        if let userId = user.userId {
            userIdLabel.text = userId
            userIdCopyButton.isEnabled = true
        }
        
        if let pushToken = explorer.apnsToken() {
            pushTokenLabel.text = pushToken
            pushTokenCopyButton.isEnabled = true
        }

        copiedLabel.alpha = 0
    }

    @IBAction func defaultIdCopyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = defaultIdLabel.text
        showCopiedLabel()
    }

    @IBAction func deviceIdCopyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = deviceIdLabel.text
        showCopiedLabel()
    }

    @IBAction func userIdCopyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = userIdLabel.text
        showCopiedLabel()
    }
    
    @IBAction func pushTokenCopyTapped(_ sender: UIButton) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = pushTokenLabel.text
        showCopiedLabel()
    }

    private func showCopiedLabel() {
        copiedLabel.alpha = 1
        UIView.animate(withDuration: 1, delay: 0, options: .transitionCrossDissolve) {
            self.copiedLabel.alpha = 0
        }
        Metrics.counter(name: "user.explorer.identifier.copy").increment()
    }

    private func initPageView() {
        experimentPageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        experimentPageViewController.view.backgroundColor = UIColor.white
        experimentPageViewController.delegate = self
        experimentPageViewController.dataSource = self
        experimentPageViewController.view.frame = experimentPageView.bounds

        addChild(experimentPageViewController)
        experimentPageView.addSubview(experimentPageViewController.view)

        abTestViewController = createController()
        featureFlagViewController = createController()
        select(experimentType: .abTest)
    }

    private func createController<T: UIViewController>() -> T {
        let controller = T.init(nibName: String(describing: T.self), bundle: HackleInternalResources.bundle)
        addChild(controller)
        controller.view.frame = experimentPageView.bounds
        return controller
    }

    @IBAction func abTestButtonTapped(_ sender: UIButton) {
        select(experimentType: .abTest)
    }

    @IBAction func featureFlagButtonTapped(_ sender: UIButton) {
        select(experimentType: .featureFlag)
    }

    private func select(experimentType: ExperimentType) {
        switch experimentType {
        case .abTest:
            experimentPageViewController.setViewControllers([abTestViewController], direction: .reverse, animated: true)
            select(button: abTestButton)
            unselect(button: featureFlagButton)
        case .featureFlag:
            experimentPageViewController.setViewControllers([featureFlagViewController], direction: .forward, animated: true)
            select(button: featureFlagButton)
            unselect(button: abTestButton)
        }
    }

    private func select(button: UIButton) {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: button.frame.height - 2, width: button.frame.width, height: 2)
        layer.backgroundColor = UIColor.black.cgColor
        layer.name = "io.hackle.experiment.button.selected"
        button.layer.addSublayer(layer)
        button.isEnabled = false
        button.setTitleColor(UIColor.black, for: .normal)

    }

    private func unselect(button: UIButton) {
        button.layer.sublayers?
            .filter { it in
                it.name == "io.hackle.experiment.button.selected"
            }
            .forEach { it in
                it.removeFromSuperlayer()
            }
        button.isEnabled = true
        button.setTitleColor(UIColor.lightGray, for: .normal)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController == featureFlagViewController {
            return abTestViewController
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController == abTestViewController {
            return featureFlagViewController
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let currentViewController = pageViewController.viewControllers?.first {
            if currentViewController == abTestViewController {
                select(experimentType: .abTest)
            } else {
                select(experimentType: .featureFlag)
            }
        }
    }
}
