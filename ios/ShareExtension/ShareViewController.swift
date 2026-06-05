// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// iOS Share Extension entry point (#2736, Epic #2687).
//
// The iOS analogue of the Android `ShareIntentChannel.kt` inbound path: it
// receives a receipt the user shared from another app (Photos, Files, Mail,
// Safari, …), copies each attachment into the SHARED App Group container, and
// hands control to the host app — which then surfaces the share through the
// SAME `ShareReceiptListener` / `ShareReceiptHandler` Dart flow already shipped
// for Android (#2735).
//
// Why an App Group + a manifest file (not the plugin route): iOS extensions run
// in a separate process with no direct channel to the Flutter engine. The
// only durable bridge is the App Group container both targets can read. So the
// extension writes:
//   * each binary attachment as `shared_receipt_<n>.<ext>` in the group dir;
//   * a `pending_share.json` manifest describing every item, in EXACTLY the
//     `{ "items": [ {kind,path|text} ], "country": "DE" }` shape the Dart
//     `SharedReceiptIntent.fromPlatform` already decodes (the same contract
//     Kotlin emits — one decoder, two platforms).
// The host app's inline `ShareIntentChannel` (in AppDelegate.swift) drains that
// manifest on launch/resume and replays it down the existing method/event
// channels. No new Dart logic — this reuses the #2735 receiver end-to-end.
//
// Activation (which share sheets show Sparkilo) is declared in this target's
// Info.plist `NSExtensionActivationRule`: images, PDFs and text/URL payloads.
//
// IMPORTANT — this file is SOURCE-TRACKED scaffolding only. It is NOT wired
// into `ios/Runner.xcodeproj/project.pbxproj` (same as `TankstellenWidget`):
// the iOS host build keeps compiling without it. A Mac developer adds the
// Share Extension target in Xcode + signs it under the Apple Developer account
// per `docs/guides/ios-share-extension.md`. Until then the file just sits on
// disk and changes nothing about the existing build.

import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

/// App Group identifier — MUST match `Runner.entitlements`,
/// `ShareExtension.entitlements`, the WidgetKit extension, and the Dart-side
/// `_iosWidgetGroupId` (`home_widget_service.dart`). All break together.
private let kAppGroupId = "group.de.tankstellen.tankstellen"

/// Custom URL scheme the extension opens to wake the host app. Registered in
/// the host `Runner/Info.plist` `CFBundleURLTypes`, and handled by
/// `AppDelegate.application(_:open:options:)`.
private let kHostShareURL = "sparkilo-share://receipt"

/// Manifest file written into the App Group container, drained by the host.
private let kManifestName = "pending_share.json"

/// The Share Extension's view controller. Headless-ish: it resolves the shared
/// items, writes them to the App Group, opens the host, and completes — the
/// host app does the actual receipt parsing / form prefill.
final class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    handleShare()
  }

  /// Resolves every attachment on every input item into the App Group, writes
  /// the manifest, then opens the host and completes the request. Failures are
  /// swallowed into a graceful completion so the share sheet never hangs.
  private func handleShare() {
    let attachments = (extensionContext?.inputItems as? [NSExtensionItem])?
      .flatMap { $0.attachments ?? [] } ?? []

    guard !attachments.isEmpty else {
      complete()
      return
    }

    resolveItems(attachments) { [weak self] items in
      guard let self = self else { return }
      if !items.isEmpty {
        self.writeManifest(items: items)
        self.openHost()
      }
      self.complete()
    }
  }

  /// Resolves the attachments to manifest entries off the main thread, then
  /// calls back on the main thread. Each provider is loaded in turn; a failing
  /// item is dropped so one bad attachment never sinks the whole share.
  private func resolveItems(
    _ providers: [NSItemProvider],
    completion: @escaping ([[String: Any]]) -> Void
  ) {
    let group = DispatchGroup()
    var items: [[String: Any]] = []
    let lock = NSLock()
    var index = 0

    func append(_ item: [String: Any]) {
      lock.lock()
      items.append(item)
      lock.unlock()
    }

    for provider in providers {
      let seq = index
      index += 1
      group.enter()
      resolve(provider, seq: seq) { item in
        if let item = item { append(item) }
        group.leave()
      }
    }

    group.notify(queue: .main) { completion(items) }
  }

  /// Resolves a single provider to a manifest entry. Order of preference:
  /// image → PDF → file (all copied into the group) → plain text / URL.
  private func resolve(
    _ provider: NSItemProvider,
    seq: Int,
    completion: @escaping ([String: Any]?) -> Void
  ) {
    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      loadFile(provider, type: UTType.image, kind: "image", seq: seq, ext: "jpg",
               completion: completion)
    } else if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
      loadFile(provider, type: UTType.pdf, kind: "pdf", seq: seq, ext: "pdf",
               completion: completion)
    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
      loadText(provider, type: UTType.plainText, completion: completion)
    } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      loadURL(provider, completion: completion)
    } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
      loadText(provider, type: UTType.text, completion: completion)
    } else {
      completion(nil)
    }
  }

  /// Copies a file-backed item (image / pdf) into the App Group container and
  /// returns its manifest entry. The OS only grants a transient read on the
  /// loaded URL, so the copy is required for the host process to read it.
  private func loadFile(
    _ provider: NSItemProvider,
    type: UTType,
    kind: String,
    seq: Int,
    ext: String,
    completion: @escaping ([String: Any]?) -> Void
  ) {
    provider.loadFileRepresentation(forTypeIdentifier: type.identifier) {
      [weak self] url, _ in
      guard let self = self, let url = url,
            let dest = self.copyIntoGroup(url, seq: seq, ext: ext) else {
        completion(nil)
        return
      }
      completion(["kind": kind, "path": dest.path])
    }
  }

  /// Loads a plain-text / text payload as a `text` manifest entry.
  private func loadText(
    _ provider: NSItemProvider,
    type: UTType,
    completion: @escaping ([String: Any]?) -> Void
  ) {
    provider.loadItem(forTypeIdentifier: type.identifier, options: nil) { value, _ in
      let text = (value as? String)
        ?? (value as? Data).flatMap { String(data: $0, encoding: .utf8) }
      guard let resolved = text, !resolved.isEmpty else {
        completion(nil)
        return
      }
      completion(["kind": "text", "text": resolved])
    }
  }

  /// A shared URL (e.g. a link to a digital receipt) is carried as text so the
  /// host's e-receipt text parser can attempt it.
  private func loadURL(
    _ provider: NSItemProvider,
    completion: @escaping ([String: Any]?) -> Void
  ) {
    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) {
      value, _ in
      guard let url = value as? URL else {
        completion(nil)
        return
      }
      completion(["kind": "text", "text": url.absoluteString])
    }
  }

  /// Copies `src` into the App Group container under a unique name and returns
  /// the destination URL, or nil on any failure.
  private func copyIntoGroup(_ src: URL, seq: Int, ext: String) -> URL? {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: kAppGroupId
    ) else { return nil }
    let stamp = Int(Date().timeIntervalSince1970 * 1000)
    let dest = container
      .appendingPathComponent("shared_receipt_\(stamp)_\(seq).\(ext)")
    do {
      if FileManager.default.fileExists(atPath: dest.path) {
        try FileManager.default.removeItem(at: dest)
      }
      try FileManager.default.copyItem(at: src, to: dest)
      return dest
    } catch {
      return nil
    }
  }

  /// Writes the manifest JSON into the App Group container in the exact shape
  /// `SharedReceiptIntent.fromPlatform` decodes. `country` mirrors the Android
  /// receiver's ISO-3166 alpha-2 region from the device locale (or omitted).
  private func writeManifest(items: [[String: Any]]) {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: kAppGroupId
    ) else { return }
    var payload: [String: Any] = ["items": items]
    if let region = Locale.current.regionCode, !region.isEmpty {
      payload["country"] = region.uppercased()
    }
    guard let data = try? JSONSerialization.data(withJSONObject: payload) else {
      return
    }
    let url = container.appendingPathComponent(kManifestName)
    try? data.write(to: url, options: .atomic)
  }

  /// Opens the host app via the custom URL scheme so it foregrounds and drains
  /// the manifest. Walks the responder chain to find an object the extension is
  /// allowed to ask to `openURL:` (extensions can't reach `UIApplication.shared`
  /// directly).
  private func openHost() {
    guard let url = URL(string: kHostShareURL) else { return }
    var responder: UIResponder? = self
    let selector = sel_registerName("openURL:")
    while let current = responder {
      if current.responds(to: selector) {
        _ = current.perform(selector, with: url)
        return
      }
      responder = current.next
    }
  }

  /// Completes the extension request, dismissing the share sheet.
  private func complete() {
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}
