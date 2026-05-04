import 'package:freezed_annotation/freezed_annotation.dart';

part 'reference_vehicle.freezed.dart';
part 'reference_vehicle.g.dart';

/// Engine induction technology (#1422 phase 1).
///
/// Drives the η_v (volumetric efficiency) defaulting helper
/// [defaultVolumetricEfficiency]: a turbocharged direct-injection engine
/// runs ~0.93 at cruise where a naturally-aspirated port-injection engine
/// runs ~0.85, so a single 0.85 catalog default systematically
/// under-fuels the live integrator on modern downsized engines until the
/// VeLearner converges (#1397).
///
/// Stored as a string in JSON via the freezed serializer so adding a new
/// type (e.g. "millerCycle", "twoStrokeDiesel") stays JSON-only.
///
/// Values:
///   - [naturallyAspirated] — atmospheric intake, no compressor.
///   - [turbocharged]       — exhaust-driven turbocharger, fixed-vane.
///   - [supercharged]       — belt-driven mechanical compressor.
///   - [vnt]                — variable-nozzle turbocharger, used on
///                            modern common-rail diesels (PSA BlueHDi,
///                            Renault dCi, VW TDI etc.). Higher BMEP
///                            range than a fixed-vane turbo.
enum InductionType { naturallyAspirated, turbocharged, supercharged, vnt }

/// Returns the typical cruise η_v for a reference vehicle's engine
/// technology (#1422 phase 1).
///
/// Used as the third tier in the fuel-rate resolution chain
/// (#1397): manual override → stored profile value (when explicitly
/// learned / non-default) → [defaultVolumetricEfficiency] → hard fallback.
///
/// Derived values come from the spec table in #1422:
///   - Atkinson cycle (Toyota HSD)        → 0.70
///   - VNT diesel (assumed DI in modern)  → 0.95
///   - Turbo / supercharged + DI          → 0.93
///   - Turbo / supercharged + port inj.   → 0.90
///   - NA + DI                            → 0.88
///   - NA + port injection (legacy fwd)   → 0.85
///
/// The legacy 0.85 path is preserved bit-for-bit so existing rows that
/// don't carry the new fields still resolve to the same value they did
/// before #1422.
double defaultVolumetricEfficiency(ReferenceVehicle v) {
  if (v.atkinsonCycle) return 0.70;
  if (v.inductionType == InductionType.vnt) return 0.95;
  if (v.inductionType == InductionType.turbocharged ||
      v.inductionType == InductionType.supercharged) {
    return v.directInjection ? 0.93 : 0.90;
  }
  return v.directInjection ? 0.88 : 0.85;
}

/// Optional human-readable basis for the helper-derived η_v default
/// (#1422 phase 2).
///
/// Returns one of 5 ARB keys to look up via `AppLocalizations`, or
/// `null` for the NA + no-DI baseline (no enrichment needed — the
/// helper output is the legacy 0.85 default and the plain
/// `(catalog: <make model>)` label already conveys everything the user
/// needs to know).
///
/// Mirrors the 5 distinct paths in [defaultVolumetricEfficiency]; the
/// `CalibrationSection` consumer uses this to extend the
/// `(catalog: Dacia Duster)` origin tag into
/// `(catalog: Dacia Duster — VNT diesel + DI default)`.
String? volumetricEfficiencyBasisKey(ReferenceVehicle v) {
  if (v.atkinsonCycle) return 'calibrationBasisAtkinson';
  if (v.inductionType == InductionType.vnt) return 'calibrationBasisVnt';
  if (v.inductionType == InductionType.turbocharged ||
      v.inductionType == InductionType.supercharged) {
    return v.directInjection
        ? 'calibrationBasisTurboDi'
        : 'calibrationBasisTurbo';
  }
  return v.directInjection ? 'calibrationBasisNaDi' : null;
}

/// A single entry in the reference vehicle catalog (#950 phase 1).
///
/// The catalog ships ~30 popular EU passenger cars compiled from
/// 2015-2024 new-car registrations. Each entry pre-fills the engine
/// quirks the OBD-II layer needs (volumetric efficiency, odometer PID
/// strategy) so the user doesn't have to discover them by hand.
///
/// Phase 1 is data + provider only. The obd2_service consumer rewrite
/// lands in phase 2; user [VehicleProfile] migration in phase 4.
///
/// All fields are `final` and the entity is immutable — the JSON asset
/// is the source of truth at app startup.
@freezed
abstract class ReferenceVehicle with _$ReferenceVehicle {
  const ReferenceVehicle._();

  const factory ReferenceVehicle({
    /// Manufacturer brand, e.g. "Peugeot", "Renault".
    required String make,

    /// Model name as marketed in Europe, e.g. "208", "Clio".
    required String model,

    /// Generation label, e.g. "II (2019-)" or "V (2020-)". Free form;
    /// purely informational for the user-facing picker.
    required String generation,

    /// First model year for this generation.
    required int yearStart,

    /// Last model year, or null if still in production.
    int? yearEnd,

    /// Engine displacement in cubic centimetres.
    required int displacementCc,

    /// One of "petrol", "diesel", "hybrid", "electric". Stored as a
    /// string (not enum) so adding a new fuel type is JSON-only.
    required String fuelType,

    /// One of "manual", "automatic". Stored as a string so the catalog
    /// can grow new transmission flavours without an entity change.
    required String transmission,

    /// Typical volumetric efficiency for this engine. Defaults to 0.85
    /// when the manufacturer doesn't publish a tuning value.
    @Default(0.85) double volumetricEfficiency,

    /// Which OBD-II PID strategy unlocks the odometer for this make.
    /// One of:
    ///
    ///   - "stdA6"   — generic OBD-II Service 01 PID A6 (rare, but the
    ///                 standards-compliant default).
    ///   - "psaUds"  — PSA family (Peugeot, Citroen, DS, Opel post-2017,
    ///                 Vauxhall) UDS-over-CAN custom PID.
    ///   - "bmwCan"  — BMW raw-CAN broadcast frame.
    ///   - "vwUds"   — VAG group (VW, Skoda, Seat, Audi) UDS PID.
    ///   - "unknown" — no working strategy known; consumer falls back to
    ///                 trip integration.
    @Default('stdA6') String odometerPidStrategy,

    /// Engine induction technology (#1422 phase 1). Drives
    /// [defaultVolumetricEfficiency]. Defaults to
    /// [InductionType.naturallyAspirated] so legacy rows without the
    /// field deserialize unchanged.
    @Default(InductionType.naturallyAspirated) InductionType inductionType,

    /// Whether the engine uses gasoline / diesel direct injection
    /// (#1422 phase 1). Defaults to false for backward-compat with
    /// rows that pre-date the schema addition.
    @Default(false) bool directInjection,

    /// Whether the engine runs the Atkinson cycle (#1422 phase 1).
    /// Toyota HSD (Prius / Yaris HSD / Auris HSD / Corolla Hybrid),
    /// Mazda Skyactiv-X. Defaults to false.
    @Default(false) bool atkinsonCycle,

    /// Optional free-form notes (e.g. "PHEV variant uses different VE").
    String? notes,
  }) = _ReferenceVehicle;

  factory ReferenceVehicle.fromJson(Map<String, dynamic> json) =>
      _$ReferenceVehicleFromJson(json);

  /// True when [year] falls inside this entry's production window.
  /// Open-ended generations ([yearEnd] == null) cover everything from
  /// [yearStart] onwards.
  bool coversYear(int year) =>
      yearStart <= year && (yearEnd ?? 9999) >= year;
}
