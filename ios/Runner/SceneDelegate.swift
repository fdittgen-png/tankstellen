// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import Flutter
import UIKit

/// Scene delegate for the Flutter host. Under the scene lifecycle this app
/// declares (`UIApplicationSceneManifest` in Info.plist), URL opens are
/// delivered HERE — not to `AppDelegate.application(_:open:options:)` — so the
/// Share Extension hand-off (#2736) is drained from the scene callbacks.
///
/// `sparkilo-share://receipt` is opened by the Share Extension after it has
/// written `pending_share.json` into the App Group; both the cold
/// (`willConnectTo`) and warm (`openURLContexts`) entry points drain the SAME
/// `ShareIntentBridge.shared` the channels are registered on (AppDelegate). The
/// actual receipt routing stays entirely in the existing Dart receiver
/// (#2735). Calling `super` keeps Flutter's own scene wiring intact.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if connectionOptions.urlContexts.contains(where: { $0.url.scheme == "sparkilo-share" }) {
      ShareIntentBridge.shared.drainPendingShare()
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    if URLContexts.contains(where: { $0.url.scheme == "sparkilo-share" }) {
      ShareIntentBridge.shared.drainPendingShare()
    }
  }
}
