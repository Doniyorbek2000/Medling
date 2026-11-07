import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Ilova fonga o'tganda (ilovalar almashtirgichida) tibbiy ma'lumotlar
  /// ko'rinmasligi uchun ekran logotipli parda bilan yopiladi.
  private var privacyCover: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(showPrivacyCover),
      name: UIApplication.willResignActiveNotification, object: nil)
    center.addObserver(
      self, selector: #selector(hidePrivacyCover),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  @objc private func showPrivacyCover() {
    guard privacyCover == nil, let window = keyWindow() else { return }
    let cover = UIView(frame: window.bounds)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.backgroundColor = .systemBackground
    let logo = UIImageView(image: UIImage(named: "LaunchImage"))
    logo.contentMode = .scaleAspectFit
    logo.frame = CGRect(x: 0, y: 0, width: 180, height: 180)
    logo.center = CGPoint(x: cover.bounds.midX, y: cover.bounds.midY)
    logo.autoresizingMask = [
      .flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin,
    ]
    cover.addSubview(logo)
    window.addSubview(cover)
    privacyCover = cover
  }

  @objc private func hidePrivacyCover() {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }

  private func keyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
