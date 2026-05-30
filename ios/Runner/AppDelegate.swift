// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
  }
}
