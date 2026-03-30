import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GeneratedPluginRegistrant.register(with: self)
    
    // MethodChannel을 통해 flavor 정보를 Flutter로 전달
    let controller = window?.rootViewController as? FlutterViewController
    let flavorChannel = FlutterMethodChannel(
      name: "com.lingorithm.kakikaki/meta",
      binaryMessenger: controller!.binaryMessenger
    )
    
    flavorChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getFlavor":
        // Bundle의 APP_FLAVOR 설정값 가져오기
        let flavor = Bundle.main.infoDictionary?["APP_FLAVOR"] as? String ?? "dev"
        result(flavor)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // URL 스킴 처리 (카카오 로그인 등 외부 라이브러리 연동용 기본 유지)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }
}