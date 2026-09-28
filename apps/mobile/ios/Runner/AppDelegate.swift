import Flutter
import ImageIO
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let deviceRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "SnapGrubDevice") {
      Self.registerDeviceChannel(messenger: deviceRegistrar.messenger())
    }
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SnapGrubOCR") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "snapgrub/ocr",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      Self.recognizeText(at: path, result: result)
    }
  }

  /// Device capabilities the design system adapts to (Low Power Mode) and
  /// cosmetic extras (alternate app icons unlocked by milestones).
  private static func registerDeviceChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "snapgrub/device", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isLowPowerMode":
        result(ProcessInfo.processInfo.isLowPowerModeEnabled)
      case "supportsAlternateIcons":
        result(UIApplication.shared.supportsAlternateIcons)
      case "setAlternateIcon":
        let name = (call.arguments as? [String: Any])?["name"] as? String
        guard UIApplication.shared.supportsAlternateIcons else {
          result(false)
          return
        }
        UIApplication.shared.setAlternateIconName(name) { error in
          result(error == nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(
      forName: .NSProcessInfoPowerStateDidChange,
      object: nil,
      queue: .main
    ) { _ in
      channel.invokeMethod("lowPowerModeChanged", arguments: ProcessInfo.processInfo.isLowPowerModeEnabled)
    }
  }

  private static func recognizeText(at path: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        DispatchQueue.main.async {
          result(FlutterError(code: "invalid_image", message: "Could not read this label photo.", details: nil))
        }
        return
      }

      let request = VNRecognizeTextRequest { request, error in
        if let error {
          DispatchQueue.main.async {
            result(FlutterError(code: "vision_ocr", message: error.localizedDescription, details: nil))
          }
          return
        }
        let text = (request.results as? [VNRecognizedTextObservation])?
          .compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n") ?? ""
        DispatchQueue.main.async { result(text) }
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true

      do {
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "vision_ocr", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
