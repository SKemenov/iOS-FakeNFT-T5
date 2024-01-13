import UIKit
import ProgressHUD
import Kingfisher

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }

    private static var customView: UIView?

    static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.show()
    }

    static func showWithoutBloсking() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.show()
    }

    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }

    static func showCustom() {
        window?.isUserInteractionEnabled = false
        self.customView = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        guard let customView = customView else { return }
        customView.backgroundColor = .clear
        window?.addSubview(customView)
        customView.center = window?.center ?? CGPoint.zero
        let activity = UIActivityIndicatorView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: customView.frame.width,
                height: customView.frame.height
            )
        )
        activity.startAnimating()
        customView.addSubview(activity)
    }

    static func dismissCustom() {
        window?.isUserInteractionEnabled = true
        customView?.removeFromSuperview()
    }
}
