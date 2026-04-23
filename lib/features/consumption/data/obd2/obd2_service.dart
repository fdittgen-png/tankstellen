import 'package:flutter/foundation.dart';

import '../../../vehicle/domain/entities/vehicle_profile.dart';
import 'elm327_protocol.dart';
import 'obd2_transport.dart';
import 'supported_pids_cache.dart';

/// Fallback engine displacement used by the speed-density fuel-rate
/// estimator when the active vehicle profile doesn't expose one
/// (#810, #812). 1000 cc = 1.0 L NA petrol — matches the Peugeot 107
/// / Aygo / C1 class that originally motivated the fallback. Kept as
/// a named constant so the no-profile case is obvious at a glance
/// and easy to update if the default assumption ever changes.
const int _defaultEngineDisplacementCc = 1000;

/// Fallback volumetric efficiency for the speed-density estimator
/// (#810, #812). 0.85 is a sensible midpoint for a NA petrol engine
/// at cruise; adaptive calibration (#815) will later narrow this per
/// vehicle from tankful reconciliation.
const double _defaultVolumetricEfficiency = 0.85;

/// High-level OBD-II service for reading vehicle data.
///
/// Wraps [Obd2Transport] and [Elm327Protocol] to provide a clean API
/// for reading odometer, speed, and other vehicle parameters.
class Obd2Service {
  final Obd2Transport _transport;

  /// Optional persistent supported-PID cache (#811). When present and
  /// a VIN (or [vehicleFallbackKey]) resolves to a cached entry,
  /// [connect] skips the 8 × `01 XX` bitmap scan entirely.
  final SupportedPidsCache? _pidsCache;

  /// Fallback cache key for when the car doesn't return a VIN (old
  /// ECUs / incompatible adapters). Typically `'${make}:${model}:${year}'`
  /// — see [SupportedPidsCache.fallbackKey].
  final String? _vehicleFallbackKey;

  /// Per-connection cache of the Mode 01 PIDs the car supports,
  /// populated by [discoverSupportedPids] or reloaded from [_pidsCache]
  /// during [connect]. `null` means "we haven't asked the car yet,
  /// so don't trust this cache to reject PIDs" (see [isPidSupported]
  /// for the exact semantics).
  Set<int>? _supportedPids;

  Obd2Service(
    this._transport, {
    SupportedPidsCache? pidsCache,
    String? vehicleFallbackKey,
  })  : _pidsCache = pidsCache,
        _vehicleFallbackKey = vehicleFallbackKey;

  /// `true` when the underlying [Obd2Transport] currently has an open
  /// connection to the vehicle's ELM327 adapter.
  bool get isConnected => _transport.isConnected;

  /// Send a raw command to the ELM327 adapter and return the raw
  /// response. Exposed for the [PidScheduler]-based trip recording
  /// loop (#814) — the scheduler dispatches individual PID commands
  /// directly and parses responses PID-by-PID, rather than going
  /// through the typed `readRpm` / `readSpeed` helpers. Keeping the
  /// escape hatch on the service lets the transport stay private.
  Future<String> sendCommand(String command) =>
      _transport.sendCommand(command);

  /// Connect and initialize the ELM327 adapter.
  ///
  /// After the init sequence, if a [SupportedPidsCache] was wired in
  /// via the constructor (#811) this also:
  ///   1. Reads the VIN from the car (Mode 09 PID 02). Falls back to
  ///      the optional `vehicleFallbackKey` when no VIN comes back.
  ///   2. Looks up the supported-PID set by that key. On cache hit,
  ///      populates the in-memory set and skips the scan entirely —
  ///      saves 8 × `01 XX` Bluetooth round-trips every session.
  ///   3. On cache miss, runs [discoverSupportedPids] and persists
  ///      the result under the chosen key for next time.
  Future<bool> connect() async {
    try {
      await _transport.connect();

      // Clear the per-connection supported-PIDs cache. A new session
      // may be a different car / different adapter firmware.
      _supportedPids = null;

      // Run initialization sequence
      for (final cmd in Elm327Protocol.initCommands) {
        await _transport.sendCommand(cmd);
        // Brief delay between init commands
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _primeSupportedPidsCache();

      return true;
    } catch (e) {
      debugPrint('OBD2 connect failed: $e');
      return false;
    }
  }

  /// Attempt to load the supported-PID set from the persistent cache
  /// (#811). Silent no-op when no cache was injected. Always swallows
  /// errors: a broken cache must not break the connect flow — worst
  /// case we fall back to blind querying, which is exactly what the
  /// adapter did before this feature landed.
  Future<void> _primeSupportedPidsCache() async {
    final cache = _pidsCache;
    if (cache == null) return;
    try {
      final key = await _resolveVehicleCacheKey();
      if (key == null) {
        debugPrint(
            'OBD2 supported-PID cache: no VIN and no fallback key — '
            'scanning blindly this session');
        return;
      }
      final cached = cache.get(key);
      if (cached != null) {
        _supportedPids = cached;
        debugPrint(
            'OBD2 supported-PID cache HIT for "$key" '
            '(${cached.length} PIDs) — skipping scan');
        return;
      }
      debugPrint('OBD2 supported-PID cache MISS for "$key" — scanning');
      final discovered = await discoverSupportedPids();
      if (discovered.isNotEmpty) {
        await cache.put(key, discovered);
      }
    } catch (e) {
      debugPrint('OBD2 supported-PID cache prime failed: $e');
    }
  }

  /// Resolve the cache key for the currently-connected vehicle.
  /// Prefers the VIN; falls back to the static [_vehicleFallbackKey]
  /// provided at construction time. Returns null when neither is
  /// available, at which point the cache is skipped this session.
  Future<String?> _resolveVehicleCacheKey() async {
    try {
      final response = await _transport.sendCommand(Elm327Protocol.vinCommand);
      final vin = Elm327Protocol.parseVin(response);
      if (vin != null && vin.isNotEmpty) return vin;
    } catch (e) {
      debugPrint('OBD2 VIN read for cache key failed: $e');
    }
    return _vehicleFallbackKey;
  }

  /// Whether [pid] is known to be supported by the connected vehicle
  /// (#811). Key semantics:
  ///
  ///   - When [discoverSupportedPids] has NOT been called yet
  ///     (cache is null), returns `true` — we don't know enough to
  ///     reject the query, so let it go through and surface NO DATA
  ///     naturally.
  ///   - When the cache IS populated and [pid] is present, returns
  ///     `true`.
  ///   - When the cache IS populated and [pid] is absent, returns
  ///     `false` — callers skip the query.
  bool isPidSupported(int pid) =>
      _supportedPids == null || _supportedPids!.contains(pid);

  /// Alias for [isPidSupported] — matches the name used in the #811
  /// issue. Same semantics: `true` when the cache is unpopulated or
  /// [pid] is present, `false` only when we know the car doesn't
  /// implement it.
  bool supportsPid(int pid) => isPidSupported(pid);

  /// Direct view of the supported-PID set for tests and diagnostics.
  /// Returns an unmodifiable empty set when discovery hasn't run —
  /// callers that want "is this supported?" should use [supportsPid]
  /// instead to respect the "unknown ⇒ allow" semantics.
  @visibleForTesting
  Set<int> get debugSupportedPids => Set.unmodifiable(_supportedPids ?? {});

  /// Read the odometer value in km.
  ///
  /// Fallback chain (#719):
  ///   1. PID A6 (standard, only on cars from ~2018+)
  ///   2. PID 31 (distance since DTC cleared) — proxy, resets on DTC
  ///   3. Manufacturer Mode 22 PID resolved from the car's VIN
  ///
  /// Returns null when every layer fails, so callers can surface
  /// "odometer not readable for your car" instead of a zero.
  Future<double?> readOdometerKm() async {
    if (!_transport.isConnected) return null;

    try {
      // 1. Direct odometer (standard PID A6)
      final a6 =
          await _transport.sendCommand(Elm327Protocol.odometerCommand);
      final odometer = Elm327Protocol.parseOdometer(a6);
      if (odometer != null) return odometer;

      // 2. Distance since DTC cleared (standard PID 31)
      final pid31 = await _transport
          .sendCommand(Elm327Protocol.distanceSinceDtcClearedCommand);
      final distance = Elm327Protocol.parseDistanceSinceDtcCleared(pid31);
      if (distance != null) return distance.toDouble();

      // 3. Manufacturer Mode 22 fallback. Identify brand from VIN and
      //    iterate every catalog entry for that brand. Silent failure
      //    on unknown-brand is intentional — we'd rather return null
      //    than spam the car with commands it rejects.
      final vinResponse =
          await _transport.sendCommand(Elm327Protocol.vinCommand);
      final vin = Elm327Protocol.parseVin(vinResponse);
      final brand = vehicleBrandFromVin(vin);
      if (brand == VehicleBrand.unknown) return null;

      for (final entry in Elm327Protocol.mfgOdometerCatalog) {
        if (entry.brand != brand) continue;
        final response = await _transport.sendCommand(entry.command);
        final value = switch (entry.kind) {
          MfgOdometerKind.threeBytesKm =>
            Elm327Protocol.parseMfgOdometer3Byte(
              response,
              expectedPidHi: entry.pidHi,
              expectedPidLo: entry.pidLo,
            ),
          MfgOdometerKind.twoBytesKm => Elm327Protocol.parseMfgOdometer2Byte(
              response,
              expectedPidHi: entry.pidHi,
              expectedPidLo: entry.pidLo,
            ),
          MfgOdometerKind.twoBytesMilesTimes10 =>
            Elm327Protocol.parseMfgOdometerMilesTimes10(
              response,
              expectedPidHi: entry.pidHi,
              expectedPidLo: entry.pidLo,
            ),
        };
        if (value != null) return value;
      }
      return null;
    } catch (e) {
      debugPrint('OBD2 readOdometer failed: $e');
      return null;
    }
  }

  /// Read current vehicle speed in km/h.
  Future<int?> readSpeedKmh() async {
    if (!_transport.isConnected) return null;

    try {
      final response =
          await _transport.sendCommand(Elm327Protocol.vehicleSpeedCommand);
      return Elm327Protocol.parseVehicleSpeed(response);
    } catch (e) {
      debugPrint('OBD2 readSpeed failed: $e');
      return null;
    }
  }

  /// Ask the adapter which Mode 01 PIDs the vehicle supports (#811).
  ///
  /// Walks the standard supported-PIDs chain: `01 00` returns a
  /// bitmap for PIDs 01–20, and bit-32 of that bitmap is set iff PIDs
  /// 21–40 are also addressable — querying `01 20` in turn returns
  /// that range, and so on up to `01 C0`. We stop as soon as a
  /// bitmap's "next-range supported" flag is clear or the query
  /// returns NO DATA.
  ///
  /// Returns the union of every PID the car implements. Callers can
  /// consult it before issuing individual PID requests — on an older
  /// car where most PIDs miss, this saves a full second of Bluetooth
  /// round-trips per polling tick.
  ///
  /// Returns an empty set when the adapter isn't connected or the
  /// first bitmap can't be read — the caller should fall back to
  /// blind querying.
  ///
  /// Also populates the internal per-connection cache, so subsequent
  /// [isPidSupported] calls short-circuit queries for PIDs the car
  /// doesn't implement. One walk per trip-recording session is
  /// enough.
  Future<Set<int>> discoverSupportedPids() async {
    if (!_transport.isConnected) return const <int>{};
    final supported = <int>{};
    for (final command in Elm327Protocol.supportedPidsCommands) {
      // Derive the 32-PID group base from the command (e.g. "0140\r"
      // → 0x40). The commands list is in lockstep with the group
      // bases, so we just hex-parse the middle two chars.
      final groupBase = int.parse(command.substring(2, 4), radix: 16);
      try {
        final response = await _transport.sendCommand(command);
        final bitmap =
            Elm327Protocol.parseSupportedPidsBitmap(response, groupBase);
        if (bitmap == null) break;
        supported.addAll(bitmap);
        // "Bit 32" of the bitmap — i.e. PID (groupBase + 32) — is
        // conventionally the "are PIDs in the next range supported?"
        // flag. If it's not in the set we just parsed, stop walking.
        final nextRangeFlag = groupBase + 32;
        if (!bitmap.contains(nextRangeFlag)) break;
      } catch (e) {
        debugPrint('OBD2 discoverSupportedPids failed on $command: $e');
        break;
      }
    }
    _supportedPids = supported;
    return supported;
  }

  /// Read current engine RPM.
  Future<double?> readRpm() async {
    if (!_transport.isConnected) return null;

    try {
      final response =
          await _transport.sendCommand(Elm327Protocol.engineRpmCommand);
      return Elm327Protocol.parseEngineRpm(response);
    } catch (e) {
      debugPrint('OBD2 readRpm failed: $e');
      return null;
    }
  }

  /// Read calculated engine load, 0–100 %. (#717)
  Future<double?> readEngineLoad() => _readDouble(
        Elm327Protocol.engineLoadCommand,
        Elm327Protocol.parseEngineLoad,
        label: 'engineLoad',
      );

  /// Read absolute throttle position, 0–100 %. (#717)
  Future<double?> readThrottlePercent() => _readDouble(
        Elm327Protocol.throttlePositionCommand,
        Elm327Protocol.parseThrottlePercent,
        label: 'throttle',
      );

  /// Read engine fuel rate in L/h. Three-step fallback chain (#717, #800):
  ///
  ///   1. **PID 5E** — direct `engine fuel rate` reading. Modern ECUs
  ///      (~2014+) answer directly. Best accuracy, preferred when
  ///      supported.
  ///   2. **PID 10 MAF** — derive fuel rate from mass air flow:
  ///      `L/h = MAF_g_per_s × 3600 / (AFR × density)`. Accepted ~5–10 %
  ///      error, still very usable. Fails on cars without a MAF sensor.
  ///   3. **MAP + IAT + RPM speed-density** — when neither direct fuel
  ///      rate nor MAF is available (e.g. Peugeot 107 1.0L 1KR-FE), use
  ///      the ideal gas law to estimate air mass flow from intake
  ///      manifold pressure, intake air temperature, engine RPM, engine
  ///      displacement, and volumetric efficiency. Accepted ~10–15 %
  ///      error — still infinitely better than the `—` placeholder the
  ///      trip summary would otherwise show.
  ///
  /// Pass the active [VehicleProfile] via [vehicle] to feed the
  /// step-3 speed-density fallback the car's real engine displacement
  /// and volumetric efficiency (#812 phase 3). When [vehicle] is null
  /// or its engine fields are null, the method falls back to
  /// [_defaultEngineDisplacementCc] / [_defaultVolumetricEfficiency]
  /// — still honest, just tuned for the 1.0 L NA petrol class (Peugeot
  /// 107 / Aygo / C1) that originally motivated the fallback.
  /// Partial profiles (e.g. displacement known, VE unknown) use the
  /// known field and fall back for the missing one.
  ///
  /// Fuel-trim correction (#813) is applied on the MAF and
  /// speed-density branches — both compute air-mass at stoichiometric
  /// AFR, but the ECU is often trimming the real mixture ±10 %. The
  /// `(1 + (STFT + LTFT) / 100)` factor closes most of the gap with
  /// pump-measured consumption. Skipped on the direct-5E path because
  /// the ECU already returns a post-trim number there.
  Future<double?> readFuelRateLPerHour({VehicleProfile? vehicle}) async {
    final engineDisplacementCc =
        vehicle?.engineDisplacementCc ?? _defaultEngineDisplacementCc;
    // VE on VehicleProfile is a non-nullable double with its own
    // default (0.85). Using it directly here is equivalent to the
    // service-level fallback for that field.
    final volumetricEfficiency =
        vehicle?.volumetricEfficiency ?? _defaultVolumetricEfficiency;
    // Step 1: direct fuel-rate PID (already post-trim — no correction).
    // Skipped when #811 discovery proved the car doesn't implement PID 5E.
    if (isPidSupported(0x5E)) {
      final direct = await _readDouble(
        Elm327Protocol.engineFuelRateCommand,
        Elm327Protocol.parseFuelRateLPerHour,
        label: 'fuelRate',
      );
      if (direct != null) return direct;
    }

    // Step 2: MAF-based estimate. Same short-circuit — a Peugeot 107
    // without a MAF sensor returns empty set on PID 10, saves the
    // Bluetooth round-trip on every tick.
    if (isPidSupported(0x10)) {
      final maf = await readMafGramsPerSecond();
      if (maf != null) {
        // Stoichiometric petrol: AFR 14.7, density ~740 g/L.
        // L/h = MAF × 3600 / (14.7 × 740).
        final rate = maf * 3600.0 / (14.7 * 740.0);
        return _applyFuelTrimCorrection(rate);
      }
    }

    // Step 3: speed-density fallback. Requires all three of MAP / IAT
    // / RPM. If any one is known-unsupported, the step can't run and
    // we surface null — there's no partial correction worth shipping.
    if (!isPidSupported(0x0B) ||
        !isPidSupported(0x0F) ||
        !isPidSupported(0x0C)) {
      return null;
    }
    final mapKpa = await readManifoldPressureKpa();
    final iatCelsius = await readIntakeAirTempCelsius();
    final rpm = await readRpm();
    if (mapKpa == null || iatCelsius == null || rpm == null) return null;
    final rate = estimateFuelRateLPerHourFromMap(
      mapKpa: mapKpa,
      iatCelsius: iatCelsius,
      rpm: rpm,
      engineDisplacementCc: engineDisplacementCc,
      volumetricEfficiency: volumetricEfficiency,
    );
    if (rate == null) return null;
    return _applyFuelTrimCorrection(rate);
  }

  /// Multiply a stoichiometric-assumption fuel rate by
  /// `(1 + (STFT + LTFT) / 100)` when both trims are readable (#813).
  /// If either trim is missing or un-parseable, returns [raw]
  /// unchanged — better to ship the raw MAF/speed-density number
  /// than one corrected by half the signal.
  Future<double> _applyFuelTrimCorrection(double raw) async {
    final stft = await readShortTermFuelTrimPercent();
    final ltft = await readLongTermFuelTrimPercent();
    if (stft == null || ltft == null) return raw;
    return applyFuelTrimCorrection(raw, stft: stft, ltft: ltft);
  }

  /// Pure-math fuel-trim correction factor (#813). Exposed for unit
  /// tests and for callers that already hold the trim values.
  ///
  /// Formula: `corrected = raw × (1 + (STFT + LTFT) / 100)`. Positive
  /// trims mean the ECU is enriching the mixture — real fuel flow is
  /// higher than what stoichiometric math predicts. Negative trims
  /// mean the opposite. Summing STFT and LTFT is standard practice
  /// (HEM Data's canonical formula); they capture fast and slow
  /// corrections respectively.
  static double applyFuelTrimCorrection(
    double raw, {
    required double stft,
    required double ltft,
  }) {
    return raw * (1.0 + (stft + ltft) / 100.0);
  }

  /// Pure-math speed-density fuel-rate estimator (#800). Split out so
  /// unit tests can verify the formula without mocking the transport.
  ///
  /// Formula:
  ///   air_flow_g_per_s = (MAP_Pa × displacement_m³ × (RPM / 120) × η_v)
  ///                      / (R × IAT_K)
  ///   fuel_rate_L_per_h = air_flow_g_per_s × 3600 / (AFR × density)
  ///
  /// R = 287 J/(kg·K) is the specific gas constant for dry air.
  /// `RPM / 120` converts crank revolutions to intake strokes per
  /// second on a 4-stroke engine (one intake per 2 crank revs).
  /// Returns null when any input is non-positive — the ideal gas law
  /// breaks down at 0 K / 0 pressure and callers should surface "no
  /// data" rather than a bogus number.
  static double? estimateFuelRateLPerHourFromMap({
    required double mapKpa,
    required double iatCelsius,
    required double rpm,
    required int engineDisplacementCc,
    required double volumetricEfficiency,
    double afr = 14.7,
    double fuelDensityGPerL = 740.0,
  }) {
    final iatKelvin = iatCelsius + 273.15;
    if (mapKpa <= 0 ||
        iatKelvin <= 0 ||
        rpm <= 0 ||
        engineDisplacementCc <= 0 ||
        volumetricEfficiency <= 0) {
      return null;
    }
    const gasConstant = 287.0; // J/(kg·K), dry air
    final mapPa = mapKpa * 1000.0;
    final displacementM3 = engineDisplacementCc / 1_000_000.0;
    final intakesPerSecond = rpm / 120.0;
    // Kilograms of air per second (ideal gas law × VE).
    final airMassKgPerS =
        (mapPa * displacementM3 * intakesPerSecond * volumetricEfficiency) /
            (gasConstant * iatKelvin);
    final airMassGPerS = airMassKgPerS * 1000.0;
    return airMassGPerS * 3600.0 / (afr * fuelDensityGPerL);
  }

  /// Read mass air flow in g/s. (#717)
  Future<double?> readMafGramsPerSecond() => _readDouble(
        Elm327Protocol.mafCommand,
        Elm327Protocol.parseMafGramsPerSecond,
        label: 'maf',
      );

  /// Read intake manifold absolute pressure (kPa). (#800)
  Future<double?> readManifoldPressureKpa() => _readDouble(
        Elm327Protocol.intakeManifoldPressureCommand,
        Elm327Protocol.parseManifoldPressureKpa,
        label: 'manifoldPressure',
      );

  /// Read intake air temperature (°C). (#800)
  Future<double?> readIntakeAirTempCelsius() => _readDouble(
        Elm327Protocol.intakeAirTempCommand,
        Elm327Protocol.parseIntakeAirTempCelsius,
        label: 'intakeAirTemp',
      );

  /// Read short-term fuel trim bank 1 (%) (#813). Fast-feedback loop
  /// correction; the ECU adjusts this constantly to hit stoich.
  Future<double?> readShortTermFuelTrimPercent() => _readDouble(
        Elm327Protocol.shortTermFuelTrimCommand,
        Elm327Protocol.parseShortTermFuelTrim,
        label: 'shortTermFuelTrim',
      );

  /// Read long-term fuel trim bank 1 (%) (#813). Slow-drifting
  /// correction that captures persistent offsets — altitude, air
  /// filter state, injector wear.
  Future<double?> readLongTermFuelTrimPercent() => _readDouble(
        Elm327Protocol.longTermFuelTrimCommand,
        Elm327Protocol.parseLongTermFuelTrim,
        label: 'longTermFuelTrim',
      );

  /// Read fuel tank level, 0–100 %. (#717)
  Future<double?> readFuelLevelPercent() => _readDouble(
        Elm327Protocol.fuelTankLevelCommand,
        Elm327Protocol.parseFuelLevelPercent,
        label: 'fuelLevel',
      );

  /// Close the transport connection. Safe to call multiple times.
  Future<void> disconnect() async {
    await _transport.disconnect();
  }

  Future<double?> _readDouble(
    String command,
    double? Function(String raw) parser, {
    required String label,
  }) async {
    if (!_transport.isConnected) return null;
    try {
      final response = await _transport.sendCommand(command);
      return parser(response);
    } catch (e) {
      debugPrint('OBD2 read $label failed: $e');
      return null;
    }
  }
}
