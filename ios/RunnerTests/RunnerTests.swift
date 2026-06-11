// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import Flutter
import UIKit
import XCTest

@testable import Runner

/// #3172 — native test coverage for the Swift bridges in AppDelegate.swift
/// (was a single empty `testExample` while the AppDelegate hosted real logic).
///
/// Kept in this one EXISTING file on purpose: a new file under
/// `ios/RunnerTests/` is not in the RunnerTests target's compile sources
/// without a `project.pbxproj` edit (the same constraint that keeps the
/// bridges inline in `AppDelegate.swift`), so adding classes here keeps the
/// suite reproducible with zero project-file churn.

// MARK: - VisionOcrBridge.pixelBlock (#3052 coordinate flip)

/// Pins the Vision → OcrBox coordinate conversion: Vision `boundingBox` is
/// normalized [0,1] with a BOTTOM-LEFT origin, the Dart-side `OcrBox` is
/// source-image PIXELS with a TOP-LEFT origin. A silent regression here
/// breaks iOS OCR (receipt + pump scans) with green CI, because the #2478
/// label-anchored extractor just stops matching anchors.
final class VisionOcrPixelBlockTests: XCTestCase {

  private func block(
    _ box: CGRect, width: CGFloat = 1000, height: CGFloat = 500
  ) -> [String: Any] {
    return VisionOcrBridge.pixelBlock(
      text: "x", normalizedBox: box, width: width, height: height)
  }

  /// Unwraps a Double payload field; `.nan` fails any accuracy assertion,
  /// so a missing/mistyped key reads as a clean test failure.
  private func d(_ dict: [String: Any], _ key: String) -> Double {
    return dict[key] as? Double ?? .nan
  }

  func testFlipsBottomLeftOriginToTopLeftPixels() {
    // Normalized box: x 0.1–0.4, y 0.2–0.6 (Vision: y measured from BOTTOM).
    let result = block(CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4))
    XCTAssertEqual(d(result, "left"), 100.0, accuracy: 1e-9)
    XCTAssertEqual(d(result, "right"), 400.0, accuracy: 1e-9)
    // top = (1 − maxY)·h = (1 − 0.6)·500; bottom = (1 − minY)·h = (1 − 0.2)·500.
    XCTAssertEqual(d(result, "top"), 200.0, accuracy: 1e-9)
    XCTAssertEqual(d(result, "bottom"), 400.0, accuracy: 1e-9)
  }

  func testBoxAtVisionBottomMapsToImageBottom() {
    // minY = 0 in Vision space = the BOTTOM edge of the image → after the
    // flip it must be the pixel bottom (= height), not the top.
    let result = block(CGRect(x: 0, y: 0, width: 1, height: 0.1))
    XCTAssertEqual(d(result, "bottom"), 500.0, accuracy: 1e-9)
    XCTAssertEqual(d(result, "top"), 450.0, accuracy: 1e-9)
  }

  func testBoxAtVisionTopMapsToImageTop() {
    // maxY = 1 in Vision space = the TOP edge of the image → pixel top 0.
    let result = block(CGRect(x: 0, y: 0.9, width: 1, height: 0.1))
    XCTAssertEqual(d(result, "top"), 0.0, accuracy: 1e-9)
    XCTAssertEqual(d(result, "bottom"), 50.0, accuracy: 1e-9)
  }

  func testFullFrameBoxSpansFullPixelDimensions() {
    let result = block(CGRect(x: 0, y: 0, width: 1, height: 1))
    XCTAssertEqual(d(result, "left"), 0.0, accuracy: 1e-9)
    XCTAssertEqual(d(result, "top"), 0.0, accuracy: 1e-9)
    XCTAssertEqual(d(result, "right"), 1000.0, accuracy: 1e-9)
    XCTAssertEqual(d(result, "bottom"), 500.0, accuracy: 1e-9)
  }

  func testTopIsAlwaysAboveBottomAndTextCarriedThrough() {
    let result = VisionOcrBridge.pixelBlock(
      text: "1.859 E10",
      normalizedBox: CGRect(x: 0.25, y: 0.5, width: 0.5, height: 0.25),
      width: 640, height: 480)
    let top = result["top"] as! Double
    let bottom = result["bottom"] as! Double
    XCTAssertLessThan(top, bottom, "top-left origin: top must be < bottom")
    XCTAssertEqual(result["text"] as? String, "1.859 E10")
  }
}

// MARK: - ShareIntentBridge.consumeManifest (#2736 share manifest)

/// Pins the consume-once manifest contract the Share Extension relies on:
/// a valid `{items:[...]}` payload is returned and the file deleted; any
/// malformed/empty manifest is rejected AND still deleted (so it can never
/// replay on the next launch).
final class ShareIntentManifestTests: XCTestCase {

  private var dir: URL!

  override func setUpWithError() throws {
    dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("manifest-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
  }

  override func tearDownWithError() throws {
    try? FileManager.default.removeItem(at: dir)
  }

  private func write(_ contents: String) throws -> URL {
    let url = dir.appendingPathComponent("pending_share.json")
    try contents.data(using: .utf8)!.write(to: url)
    return url
  }

  func testValidManifestIsReturnedAndConsumedOnce() throws {
    let url = try write(
      #"{"items":[{"path":"/tmp/receipt.jpg","mimeType":"image/jpeg"}],"country":"DE"}"#)

    let payload = ShareIntentBridge.consumeManifest(at: url)

    XCTAssertNotNil(payload)
    XCTAssertEqual(payload?["country"] as? String, "DE")
    XCTAssertEqual((payload?["items"] as? [Any])?.count, 1)
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: url.path),
      "manifest must be deleted after a successful read (consume once)")
    XCTAssertNil(
      ShareIntentBridge.consumeManifest(at: url),
      "a second read must find nothing — a share is consumed exactly once")
  }

  func testMissingManifestIsANilNoOp() {
    let url = dir.appendingPathComponent("does_not_exist.json")
    XCTAssertNil(ShareIntentBridge.consumeManifest(at: url))
  }

  func testMalformedJsonIsRejectedAndStillDeleted() throws {
    let url = try write("{not json at all")

    XCTAssertNil(ShareIntentBridge.consumeManifest(at: url))
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: url.path),
      "a malformed manifest must be deleted BEFORE parsing so it can't replay")
  }

  func testEmptyItemsIsRejected() throws {
    let url = try write(#"{"items":[],"country":"FR"}"#)
    XCTAssertNil(ShareIntentBridge.consumeManifest(at: url))
  }

  func testNonArrayItemsIsRejected() throws {
    let url = try write(#"{"items":"nope"}"#)
    XCTAssertNil(ShareIntentBridge.consumeManifest(at: url))
  }
}
