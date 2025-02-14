//
//  UIBlockingProgressHUD.swift
//  FakeNFT
//
//  Created by Aleksey Kolesnikov on 19.12.2023.
//

import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.windows.first
    }

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
}
