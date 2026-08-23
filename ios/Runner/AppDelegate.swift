import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var privacyOverlay: UIView?
  private var isProtectionEnabled: Bool = true

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let securityChannel = FlutterMethodChannel(name: "cashtrack/security",
                                              binaryMessenger: controller.binaryMessenger)

    securityChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
      if call.method == "setScreenshotProtection" {
        if let args = call.arguments as? [String: Any],
           let enabled = args["enabled"] as? Bool {
          self?.isProtectionEnabled = enabled
          result(true)
        } else {
          result(false)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Privacy Protection for App Switcher

  override func applicationWillResignActive(_ application: UIApplication) {
    if isProtectionEnabled {
      showPrivacyOverlay()
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    hidePrivacyOverlay()
  }

  private func showPrivacyOverlay() {
    guard privacyOverlay == nil else { return }

    if let window = UIApplication.shared.windows.first {
      let blurEffect = UIBlurEffect(style: .dark)
      let blurEffectView = UIVisualEffectView(effect: blurEffect)
      blurEffectView.frame = window.bounds
      blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

      privacyOverlay = blurEffectView
      window.addSubview(blurEffectView)
    }
  }

  private func hidePrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }
}
