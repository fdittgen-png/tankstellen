# Changelog

All notable changes to this project will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/).

## [6.0.0] - 2026-06-07 (Build 5133)

First public production release.

### Added

- Engine-power-aware driving/eco scoring — low-power cars are scored proportionally for hard acceleration, with a per-vehicle power field (auto-filled from the catalogue, overridable).
- Route/itinerary map now shows the fuel stations along your trip with the route line.

### Fixed

- OBD2 reliability overhaul: reliable multi-adapter connection (BLE + Classic), automatic reconnection when the link drops, transport-aware connect (Classic adapters no longer waste time on a doomed BLE attempt), and robust `0100` protocol detection so live data (RPM/speed/fuel) actually flows.
- Driving analysis: no more phantom hard-brake/acceleration penalties from GPS noise; combustion-health magnitude corrected; trip distance no longer over-counted on GPS-only trips.

### Changed

- Unified, faster station-map rendering across all map views.
