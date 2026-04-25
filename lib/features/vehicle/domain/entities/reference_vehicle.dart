import 'package:freezed_annotation/freezed_annotation.dart';

part 'reference_vehicle.freezed.dart';
part 'reference_vehicle.g.dart';

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
