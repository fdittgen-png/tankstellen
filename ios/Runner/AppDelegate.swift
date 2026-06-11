// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import Flutter
import UIKit
import Vision
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Host-side bridge for the iOS Share Extension (#2736, Epic #2687).
  ///
  /// The extension (`ios/ShareExtension/ShareViewController.swift`) writes the
  /// shared receipt + a `pending_share.json` manifest into the App Group
  /// container, then opens `sparkilo-share://receipt`. This drains that
  /// manifest and replays it down the SAME `tankstellen/share_intent/*`
  /// channels the Android `ShareIntentChannel.kt` feeds — so the existing Dart
  /// `ShareReceiptListener` / `ShareReceiptHandler` (#2735) handles iOS shares
  /// with no new Dart code.
  ///
  /// Kept INLINE in this file (not a separate Swift file) on purpose: a new
  /// file under `ios/Runner/` is NOT in the Runner target's compile sources
  /// until a Mac developer adds it in Xcode, and referencing an uncompiled
  /// class would break the build. Defined in `AppDelegate.swift` — already in
  /// the target — it compiles today with zero `project.pbxproj` edit. On a
  /// build without the extension installed the manifest never exists, so every
  /// entry point here is a harmless no-op (`getInitialShare` → nil).
  ///
  /// Shared singleton so `SceneDelegate` (which handles the warm URL-open under
  /// the scene lifecycle this app uses) drains the SAME bridge instance the
  /// channels are registered on.
  private let shareIntent = ShareIntentBridge.shared

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // #3167 — capture the Core Bluetooth state-restoration launch signal
    // FIRST: when iOS relaunches the app in the background because the
    // paired OBD2 adapter completed a pending connect, `launchOptions`
    // carries `.bluetoothCentrals` with the restore identifiers of the
    // central managers being restored. The Dart side queries this via the
    // `tankstellen/ios_state_restoration` channel to resume hands-free
    // auto-recording and tag the connect trace origin.
    StateRestorationBridge.shared.captureLaunchOptions(launchOptions)

    // #2414 — Tier-1 background scan on iOS via the workmanager iOS backend
    // (BGTaskScheduler / BGAppRefreshTask).
    //
    // workmanager 0.9.x: a Dart `Workmanager().registerPeriodicTask(id, id)`
    // is mapped onto a BGAppRefreshTask. iOS requires the identifier to be
    // registered natively here AND listed under
    // `BGTaskSchedulerPermittedIdentifiers` in Info.plist. The Dart
    // `uniqueName` must equal this identifier
    // (`IosBackgroundTaskIds.appRefresh` on the Dart side).
    //
    // The frequency is iOS-controlled and OS-budgeted — the value below is a
    // *hint*; iOS schedules BGAppRefresh opportunistically against the user's
    // app-usage pattern and may run it far less often. Background scanning is
    // best-effort, never real-time. (Doc:
    // https://docs.page/fluttercommunity/flutter_workmanager/quickstart —
    // "Option C: Periodic Tasks with Custom Frequency".)
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "de.tankstellen.tankstellen.background",
      frequency: NSNumber(value: 30 * 60)  // 30 min hint (15 min minimum)
    )

    // Make the rest of the app's plugins (Hive/path_provider, local
    // notifications, etc.) available inside the headless background engine
    // that workmanager spins up for a BGAppRefresh/performFetch wake.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Register the share-intent channels on the implicit engine's messenger
    // and immediately scan for a cold-launch share the extension left behind.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ShareIntentBridge") {
      shareIntent.register(messenger: registrar.messenger())
    }
    // #3052 — native Apple Vision text OCR for receipt + pump-display scans
    // (replaces Google ML Kit on iOS; Android keeps ML Kit).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VisionOcrBridge") {
      VisionOcrBridge.shared.register(messenger: registrar.messenger())
    }
    // #3167 — Core Bluetooth state-restoration launch bridge (hands-free
    // auto-record Phase 3).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StateRestorationBridge") {
      StateRestorationBridge.shared.register(messenger: registrar.messenger())
    }
  }

  /// Handles the `sparkilo-share://receipt` URL the Share Extension opens to
  /// wake the host. This fires on builds WITHOUT the scene lifecycle; under the
  /// scene manifest this app declares, the warm URL open is delivered to
  /// `SceneDelegate.scene(_:openURLContexts:)` instead (see SceneDelegate). A
  /// non-share URL is passed to `super` so other deep links keep working.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "sparkilo-share" {
      shareIntent.drainPendingShare()
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

/// In-repo, plugin-free bridge that serves the `tankstellen/share_intent/*`
/// method + event channels on iOS by draining the Share Extension's App Group
/// manifest. The exact host counterpart of Android's `ShareIntentChannel.kt`,
/// emitting the IDENTICAL `{ "items": [...], "country": "XX" }` payload that
/// `SharedReceiptIntent.fromPlatform` already decodes.
final class ShareIntentBridge: NSObject, FlutterStreamHandler {
  /// Single instance both `AppDelegate` and `SceneDelegate` reach, so the
  /// scene-lifecycle warm URL-open drains the bridge the channels live on.
  static let shared = ShareIntentBridge()

  private static let appGroupId = "group.de.tankstellen.tankstellen"
  private static let manifestName = "pending_share.json"
  private static let methodChannelName = "tankstellen/share_intent/methods"
  private static let eventChannelName = "tankstellen/share_intent/events"

  private var eventSink: FlutterEventSink?
  /// A share decoded before Dart subscribed (cold launch); drained by
  /// `getInitialShare`.
  private var pendingInitial: [String: Any]?

  /// Wires both channels onto `messenger`. Called once when the Flutter engine
  /// is ready (see `didInitializeImplicitFlutterEngine`).
  func register(messenger: FlutterBinaryMessenger) {
    let methods = FlutterMethodChannel(name: Self.methodChannelName, binaryMessenger: messenger)
    methods.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getInitialShare":
        let payload = self?.pendingInitial
        self?.pendingInitial = nil
        result(payload)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let events = FlutterEventChannel(name: Self.eventChannelName, binaryMessenger: messenger)
    events.setStreamHandler(self)

    // The extension may have left a manifest from a cold launch before the
    // channels existed — pick it up now so `getInitialShare` can return it.
    drainPendingShare()
  }

  // MARK: FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  /// Reads + deletes the App Group manifest the extension wrote. If a Dart
  /// subscriber is live (warm) the payload is emitted on the event channel;
  /// otherwise it is cached for `getInitialShare` (cold). A missing or
  /// malformed manifest is a silent no-op — the common case on a build with no
  /// extension installed.
  func drainPendingShare() {
    guard let payload = readManifest() else { return }
    if let sink = eventSink {
      sink(payload)
    } else {
      pendingInitial = payload
    }
  }

  /// Reads `pending_share.json` from the App Group container, validates it is a
  /// non-empty `{items:[...]}` map, deletes it (so a share is consumed once),
  /// and returns the channel payload. Returns nil on any failure.
  private func readManifest() -> [String: Any]? {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: Self.appGroupId
    ) else { return nil }
    let url = container.appendingPathComponent(Self.manifestName)
    guard let data = try? Data(contentsOf: url) else { return nil }
    // Consume once — delete before parsing so a malformed file can't replay.
    try? FileManager.default.removeItem(at: url)
    guard
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let items = json["items"] as? [Any], !items.isEmpty
    else { return nil }
    return json
  }
}

/// #3052 — native Apple **Vision** text OCR, serving the `tankstellen/vision_ocr`
/// MethodChannel. Replaces Google ML Kit on iOS (on-device, no Google
/// dependency, builds on the simulator). Returns the flat text plus per-line
/// boxes in source-image PIXEL coordinates with a TOP-LEFT origin — matching
/// the `OcrBox` shape Android's ML Kit adapter produces — so the #2478
/// label-anchored receipt/pump extractor stays engine-agnostic.
///
/// Inline in AppDelegate.swift (not a separate file) on purpose: a new file
/// under ios/Runner/ is not in the Runner target's compile sources without a
/// project.pbxproj edit (see the ShareIntentBridge note above), so defining it
/// here keeps the build green with zero pbxproj change.
final class VisionOcrBridge {
  static let shared = VisionOcrBridge()
  private static let channelName = "tankstellen/vision_ocr"

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "recognizeText":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(nil)
          return
        }
        let languageCorrection = args["languageCorrection"] as? Bool ?? true
        let languages = args["languages"] as? [String] ?? []
        Self.recognize(
          path: path,
          languageCorrection: languageCorrection,
          languages: languages,
          result: result
        )
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Runs `VNRecognizeTextRequest` on the image at [path] off the main thread
  /// and returns `{ text: String, blocks: [{text,left,top,right,bottom}] }`
  /// (pixel, top-left). Any failure resolves to nil so the Dart caller degrades
  /// exactly as the ML Kit path did. `languageCorrection` is off for 7-segment
  /// pump displays (digits, not prose).
  private static func recognize(
    path: String,
    languageCorrection: Bool,
    languages: [String],
    result: @escaping FlutterResult
  ) {
    guard
      let image = UIImage(contentsOfFile: path),
      let cgImage = image.cgImage
    else {
      result(nil)
      return
    }
    let width = CGFloat(cgImage.width)
    let height = CGFloat(cgImage.height)

    let request = VNRecognizeTextRequest { request, error in
      func finish(_ value: Any?) {
        DispatchQueue.main.async { result(value) }
      }
      if error != nil {
        finish(nil)
        return
      }
      let observations = request.results as? [VNRecognizedTextObservation] ?? []
      var blocks: [[String: Any]] = []
      var lines: [String] = []
      for observation in observations {
        guard let candidate = observation.topCandidates(1).first else { continue }
        let text = candidate.string
        if text.isEmpty { continue }
        lines.append(text)
        // Vision boundingBox: normalized [0,1], origin BOTTOM-LEFT. Convert to
        // source-image PIXELS with a TOP-LEFT origin (flip Y) to match OcrBox.
        let box = observation.boundingBox
        let left = box.minX * width
        let right = box.maxX * width
        let top = (1.0 - box.maxY) * height
        let bottom = (1.0 - box.minY) * height
        blocks.append([
          "text": text,
          "left": Double(left),
          "top": Double(top),
          "right": Double(right),
          "bottom": Double(bottom),
        ])
      }
      finish(["text": lines.joined(separator: "\n"), "blocks": blocks])
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = languageCorrection
    if !languages.isEmpty {
      request.recognitionLanguages = languages
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
      do {
        try handler.perform([request])
      } catch {
        DispatchQueue.main.async { result(nil) }
      }
    }
  }
}

/// #3167 — host-side half of the Core Bluetooth state-restoration wiring
/// (hands-free auto-record Phase 3, Epic #3165), serving the
/// `tankstellen/ios_state_restoration` MethodChannel.
///
/// When the paired ELM327/OBDLink adapter powers up while the app is
/// terminated, iOS completes the pending connect flutter_blue_plus queued
/// (`CBCentralManagerOptionRestoreIdentifierKey` is set via
/// `setOptions(restoreState: true)` on the Dart side) and relaunches the
/// app into the background with `.bluetoothCentrals` in `launchOptions` —
/// the array of central-manager restore identifiers being restored. The
/// FBP plugin handles `centralManager:willRestoreState:` natively; what it
/// does NOT surface to Dart is the LAUNCH signal itself. This bridge
/// captures it so the Dart `IosStateRestorationService` can (a) resume the
/// auto-record coordinator and (b) stamp `stateRestoration` as the connect
/// trace origin for field exports.
///
/// Inline in AppDelegate.swift (not a separate file) on purpose: a new file
/// under ios/Runner/ is not in the Runner target's compile sources without
/// a project.pbxproj edit (see the ShareIntentBridge note above), so
/// defining it here keeps the build green with zero pbxproj change.
final class StateRestorationBridge {
  static let shared = StateRestorationBridge()
  private static let channelName = "tankstellen/ios_state_restoration"

  /// Restore identifiers from `UIApplication.LaunchOptionsKey.bluetoothCentrals`,
  /// captured in `didFinishLaunchingWithOptions`. Nil on a normal user launch.
  /// NOT consumed on read — the Dart service caches + one-shots it itself, and
  /// an idempotent getter keeps a hot-restart from losing the signal.
  private var launchBluetoothCentralIds: [String]?

  /// Called first thing in `didFinishLaunchingWithOptions` so the signal is
  /// stored before any Flutter engine (foreground or headless) spins up.
  func captureLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
    if let centrals = launchOptions?[.bluetoothCentrals] as? [String] {
      launchBluetoothCentralIds = centrals
    }
  }

  /// Wires the method channel onto `messenger`. Called once when the Flutter
  /// engine is ready (see `didInitializeImplicitFlutterEngine`).
  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getLaunchBluetoothCentralIds":
        result(self?.launchBluetoothCentralIds)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
