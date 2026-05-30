// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'obd2_session_diagnostic.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Obd2SessionDiagnostic {

/// Transport flavour that carried this session: `'ble'`, `'classic'`,
/// `'usb'`, or a future link kind. Null until [beginSession] stamps it.
@JsonKey(name: 'lk') String? get linkKind;/// Redacted adapter MAC (the existing `_redactMac` form, e.g.
/// `AA:BB:**:**:**:FF`). Null when unknown / not yet recorded.
@JsonKey(name: 'mac') String? get redactedMac;// ---- Adapter identity (filled by recordAdapterIdentity) -----------
/// ELM firmware banner version string (e.g. `'ELM327 v1.5'`). Null
/// until the handshake reads ATI.
@JsonKey(name: 'ev') String? get elmVersion;/// Auto-detected OBD protocol digit (ELM `ATDPN` reply, e.g. `'6'`
/// for ISO 15765-4 CAN 11/500). Null until detected.
@JsonKey(name: 'pd') String? get protocolDigit;/// Negotiated BLE ATT MTU (bytes). Null for classic/USB links or
/// before negotiation.
@JsonKey(name: 'mtu') int? get mtu;/// True when this session reused a warm (already-initialised) adapter
/// rather than running the full cold handshake. Null until known.
@JsonKey(name: 'ws') bool? get warmStart;/// Firmware-derived runtime capability tier name (#2465) — one of
/// `'standardOnly'` / `'oemPidsCapable'` / `'passiveCanCapable'`.
/// Wave 1 records the firmware-CLAIMED tier; Wave 2 will record the
/// value reconciled by the lazy multi-frame probe. Null until the
/// handshake reads ATI.
@JsonKey(name: 'ct') String? get capabilityTier;/// Redacted ELM init/handshake transcript, capped one-shot at
/// [maxTranscriptLines] by the collector. Oldest-first.
@JsonKey(name: 'tx') List<Obd2HandshakeLine> get initTranscript;// ---- Per-PID outcome table (Wave 2 fills; Wave 1 leaves empty) ----
/// Map from a poll command (e.g. `'010C'`) to its 5-way outcome +
/// latency row. Bounded by the fixed set of polled PIDs.
@JsonKey(name: 'pid') Map<String, Obd2PidStat> get pidStats;// ---- Connection lifecycle counters --------------------------------
/// Connection-lifecycle counters (attempts/successes/drops/reconnects
/// + time-to-connect reservoirs).
@JsonKey(name: 'conn') Obd2ConnectionStats get connection;// ---- Scheduler health (Wave 2 fills) ------------------------------
/// Achieved scheduler tick-rate (Hz), back-pressure skips, governor
/// demotions.
@JsonKey(name: 'sch') Obd2SchedulerStats get scheduler;// ---- Framing counters ---------------------------------------------
/// Wire-framing counters (partial frames / leftover bytes / stray
/// prompts / garbage reads).
@JsonKey(name: 'frm') Obd2FramingStats get framing;/// Per-tick fuel-resolution-tier distribution: branch tag → tick
/// count (e.g. `{'pid5E': 412, 'maf': 88, 'speedDensity': 3}`).
@JsonKey(name: 'ft') Map<String, int> get fuelTierTicks;/// Fuel-tier downgrade cause rolled up FREE from the breadcrumb
/// collector (#2469): `total` samples seen vs `suspicious` samples that
/// tripped a sanity flag (suspicious-low / 5E-vs-MAF divergent). A high
/// suspicious ratio alongside a [fuelTierTicks] skewed away from `pid5E`
/// is the downgrade-cause signature. Null/zero until Wave 2 rolls it up.
@JsonKey(name: 'fd') Obd2FuelDowngradeStats get fuelDowngrade;/// How long the session was actively polling, in whole seconds — the
/// `activeSeconds` term of the completeness expected-reads formula.
/// 0 until Wave 2 stamps it.
@JsonKey(name: 'as') int get sessionActiveSeconds;/// Discovered-supported tri-state per polled command (#2469):
/// `'supported'` / `'unsupported'` / `'unknown'`. Sourced from the
/// resolver's discovered set ∩ target set; `'unknown'` for every command
/// when discovery never ran (probe-less clone / blind session). Empty
/// until Wave 2 records it.
@JsonKey(name: 'tri') Map<String, String> get discoveredSupported;// ---- Completeness (Wave 2 fills; null/zero for now) ---------------
/// Σ(targetHz × activeSeconds) — the expected number of reads if the
/// scheduler had hit every target. Null until Wave 2 computes it.
@JsonKey(name: 'er') int? get expectedReads;/// Reads actually achieved this session. Null until Wave 2.
@JsonKey(name: 'ar') int? get achievedReads;/// `achievedReads / expectedReads` as a 0–100 percentage. Null until
/// Wave 2.
@JsonKey(name: 'cp') double? get completenessPercent;/// Per-tier completeness rollup (overall + 5/2/0.5/0.1 Hz tiers +
/// active duty cycle + emit-index gaps). Empty default until Wave 2
/// computes it via `summariseObd2Completeness`.
@JsonKey(name: 'cm') Obd2CompletenessStats get completeness;
/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2SessionDiagnosticCopyWith<Obd2SessionDiagnostic> get copyWith => _$Obd2SessionDiagnosticCopyWithImpl<Obd2SessionDiagnostic>(this as Obd2SessionDiagnostic, _$identity);

  /// Serializes this Obd2SessionDiagnostic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2SessionDiagnostic&&(identical(other.linkKind, linkKind) || other.linkKind == linkKind)&&(identical(other.redactedMac, redactedMac) || other.redactedMac == redactedMac)&&(identical(other.elmVersion, elmVersion) || other.elmVersion == elmVersion)&&(identical(other.protocolDigit, protocolDigit) || other.protocolDigit == protocolDigit)&&(identical(other.mtu, mtu) || other.mtu == mtu)&&(identical(other.warmStart, warmStart) || other.warmStart == warmStart)&&(identical(other.capabilityTier, capabilityTier) || other.capabilityTier == capabilityTier)&&const DeepCollectionEquality().equals(other.initTranscript, initTranscript)&&const DeepCollectionEquality().equals(other.pidStats, pidStats)&&(identical(other.connection, connection) || other.connection == connection)&&(identical(other.scheduler, scheduler) || other.scheduler == scheduler)&&(identical(other.framing, framing) || other.framing == framing)&&const DeepCollectionEquality().equals(other.fuelTierTicks, fuelTierTicks)&&(identical(other.fuelDowngrade, fuelDowngrade) || other.fuelDowngrade == fuelDowngrade)&&(identical(other.sessionActiveSeconds, sessionActiveSeconds) || other.sessionActiveSeconds == sessionActiveSeconds)&&const DeepCollectionEquality().equals(other.discoveredSupported, discoveredSupported)&&(identical(other.expectedReads, expectedReads) || other.expectedReads == expectedReads)&&(identical(other.achievedReads, achievedReads) || other.achievedReads == achievedReads)&&(identical(other.completenessPercent, completenessPercent) || other.completenessPercent == completenessPercent)&&(identical(other.completeness, completeness) || other.completeness == completeness));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,linkKind,redactedMac,elmVersion,protocolDigit,mtu,warmStart,capabilityTier,const DeepCollectionEquality().hash(initTranscript),const DeepCollectionEquality().hash(pidStats),connection,scheduler,framing,const DeepCollectionEquality().hash(fuelTierTicks),fuelDowngrade,sessionActiveSeconds,const DeepCollectionEquality().hash(discoveredSupported),expectedReads,achievedReads,completenessPercent,completeness]);

@override
String toString() {
  return 'Obd2SessionDiagnostic(linkKind: $linkKind, redactedMac: $redactedMac, elmVersion: $elmVersion, protocolDigit: $protocolDigit, mtu: $mtu, warmStart: $warmStart, capabilityTier: $capabilityTier, initTranscript: $initTranscript, pidStats: $pidStats, connection: $connection, scheduler: $scheduler, framing: $framing, fuelTierTicks: $fuelTierTicks, fuelDowngrade: $fuelDowngrade, sessionActiveSeconds: $sessionActiveSeconds, discoveredSupported: $discoveredSupported, expectedReads: $expectedReads, achievedReads: $achievedReads, completenessPercent: $completenessPercent, completeness: $completeness)';
}


}

/// @nodoc
abstract mixin class $Obd2SessionDiagnosticCopyWith<$Res>  {
  factory $Obd2SessionDiagnosticCopyWith(Obd2SessionDiagnostic value, $Res Function(Obd2SessionDiagnostic) _then) = _$Obd2SessionDiagnosticCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'lk') String? linkKind,@JsonKey(name: 'mac') String? redactedMac,@JsonKey(name: 'ev') String? elmVersion,@JsonKey(name: 'pd') String? protocolDigit,@JsonKey(name: 'mtu') int? mtu,@JsonKey(name: 'ws') bool? warmStart,@JsonKey(name: 'ct') String? capabilityTier,@JsonKey(name: 'tx') List<Obd2HandshakeLine> initTranscript,@JsonKey(name: 'pid') Map<String, Obd2PidStat> pidStats,@JsonKey(name: 'conn') Obd2ConnectionStats connection,@JsonKey(name: 'sch') Obd2SchedulerStats scheduler,@JsonKey(name: 'frm') Obd2FramingStats framing,@JsonKey(name: 'ft') Map<String, int> fuelTierTicks,@JsonKey(name: 'fd') Obd2FuelDowngradeStats fuelDowngrade,@JsonKey(name: 'as') int sessionActiveSeconds,@JsonKey(name: 'tri') Map<String, String> discoveredSupported,@JsonKey(name: 'er') int? expectedReads,@JsonKey(name: 'ar') int? achievedReads,@JsonKey(name: 'cp') double? completenessPercent,@JsonKey(name: 'cm') Obd2CompletenessStats completeness
});


$Obd2ConnectionStatsCopyWith<$Res> get connection;$Obd2SchedulerStatsCopyWith<$Res> get scheduler;$Obd2FramingStatsCopyWith<$Res> get framing;$Obd2FuelDowngradeStatsCopyWith<$Res> get fuelDowngrade;$Obd2CompletenessStatsCopyWith<$Res> get completeness;

}
/// @nodoc
class _$Obd2SessionDiagnosticCopyWithImpl<$Res>
    implements $Obd2SessionDiagnosticCopyWith<$Res> {
  _$Obd2SessionDiagnosticCopyWithImpl(this._self, this._then);

  final Obd2SessionDiagnostic _self;
  final $Res Function(Obd2SessionDiagnostic) _then;

/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? linkKind = freezed,Object? redactedMac = freezed,Object? elmVersion = freezed,Object? protocolDigit = freezed,Object? mtu = freezed,Object? warmStart = freezed,Object? capabilityTier = freezed,Object? initTranscript = null,Object? pidStats = null,Object? connection = null,Object? scheduler = null,Object? framing = null,Object? fuelTierTicks = null,Object? fuelDowngrade = null,Object? sessionActiveSeconds = null,Object? discoveredSupported = null,Object? expectedReads = freezed,Object? achievedReads = freezed,Object? completenessPercent = freezed,Object? completeness = null,}) {
  return _then(_self.copyWith(
linkKind: freezed == linkKind ? _self.linkKind : linkKind // ignore: cast_nullable_to_non_nullable
as String?,redactedMac: freezed == redactedMac ? _self.redactedMac : redactedMac // ignore: cast_nullable_to_non_nullable
as String?,elmVersion: freezed == elmVersion ? _self.elmVersion : elmVersion // ignore: cast_nullable_to_non_nullable
as String?,protocolDigit: freezed == protocolDigit ? _self.protocolDigit : protocolDigit // ignore: cast_nullable_to_non_nullable
as String?,mtu: freezed == mtu ? _self.mtu : mtu // ignore: cast_nullable_to_non_nullable
as int?,warmStart: freezed == warmStart ? _self.warmStart : warmStart // ignore: cast_nullable_to_non_nullable
as bool?,capabilityTier: freezed == capabilityTier ? _self.capabilityTier : capabilityTier // ignore: cast_nullable_to_non_nullable
as String?,initTranscript: null == initTranscript ? _self.initTranscript : initTranscript // ignore: cast_nullable_to_non_nullable
as List<Obd2HandshakeLine>,pidStats: null == pidStats ? _self.pidStats : pidStats // ignore: cast_nullable_to_non_nullable
as Map<String, Obd2PidStat>,connection: null == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as Obd2ConnectionStats,scheduler: null == scheduler ? _self.scheduler : scheduler // ignore: cast_nullable_to_non_nullable
as Obd2SchedulerStats,framing: null == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as Obd2FramingStats,fuelTierTicks: null == fuelTierTicks ? _self.fuelTierTicks : fuelTierTicks // ignore: cast_nullable_to_non_nullable
as Map<String, int>,fuelDowngrade: null == fuelDowngrade ? _self.fuelDowngrade : fuelDowngrade // ignore: cast_nullable_to_non_nullable
as Obd2FuelDowngradeStats,sessionActiveSeconds: null == sessionActiveSeconds ? _self.sessionActiveSeconds : sessionActiveSeconds // ignore: cast_nullable_to_non_nullable
as int,discoveredSupported: null == discoveredSupported ? _self.discoveredSupported : discoveredSupported // ignore: cast_nullable_to_non_nullable
as Map<String, String>,expectedReads: freezed == expectedReads ? _self.expectedReads : expectedReads // ignore: cast_nullable_to_non_nullable
as int?,achievedReads: freezed == achievedReads ? _self.achievedReads : achievedReads // ignore: cast_nullable_to_non_nullable
as int?,completenessPercent: freezed == completenessPercent ? _self.completenessPercent : completenessPercent // ignore: cast_nullable_to_non_nullable
as double?,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as Obd2CompletenessStats,
  ));
}
/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2ConnectionStatsCopyWith<$Res> get connection {
  
  return $Obd2ConnectionStatsCopyWith<$Res>(_self.connection, (value) {
    return _then(_self.copyWith(connection: value));
  });
}/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2SchedulerStatsCopyWith<$Res> get scheduler {
  
  return $Obd2SchedulerStatsCopyWith<$Res>(_self.scheduler, (value) {
    return _then(_self.copyWith(scheduler: value));
  });
}/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2FramingStatsCopyWith<$Res> get framing {
  
  return $Obd2FramingStatsCopyWith<$Res>(_self.framing, (value) {
    return _then(_self.copyWith(framing: value));
  });
}/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2FuelDowngradeStatsCopyWith<$Res> get fuelDowngrade {
  
  return $Obd2FuelDowngradeStatsCopyWith<$Res>(_self.fuelDowngrade, (value) {
    return _then(_self.copyWith(fuelDowngrade: value));
  });
}/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2CompletenessStatsCopyWith<$Res> get completeness {
  
  return $Obd2CompletenessStatsCopyWith<$Res>(_self.completeness, (value) {
    return _then(_self.copyWith(completeness: value));
  });
}
}


/// Adds pattern-matching-related methods to [Obd2SessionDiagnostic].
extension Obd2SessionDiagnosticPatterns on Obd2SessionDiagnostic {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2SessionDiagnostic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2SessionDiagnostic() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2SessionDiagnostic value)  $default,){
final _that = this;
switch (_that) {
case _Obd2SessionDiagnostic():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2SessionDiagnostic value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2SessionDiagnostic() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'lk')  String? linkKind, @JsonKey(name: 'mac')  String? redactedMac, @JsonKey(name: 'ev')  String? elmVersion, @JsonKey(name: 'pd')  String? protocolDigit, @JsonKey(name: 'mtu')  int? mtu, @JsonKey(name: 'ws')  bool? warmStart, @JsonKey(name: 'ct')  String? capabilityTier, @JsonKey(name: 'tx')  List<Obd2HandshakeLine> initTranscript, @JsonKey(name: 'pid')  Map<String, Obd2PidStat> pidStats, @JsonKey(name: 'conn')  Obd2ConnectionStats connection, @JsonKey(name: 'sch')  Obd2SchedulerStats scheduler, @JsonKey(name: 'frm')  Obd2FramingStats framing, @JsonKey(name: 'ft')  Map<String, int> fuelTierTicks, @JsonKey(name: 'fd')  Obd2FuelDowngradeStats fuelDowngrade, @JsonKey(name: 'as')  int sessionActiveSeconds, @JsonKey(name: 'tri')  Map<String, String> discoveredSupported, @JsonKey(name: 'er')  int? expectedReads, @JsonKey(name: 'ar')  int? achievedReads, @JsonKey(name: 'cp')  double? completenessPercent, @JsonKey(name: 'cm')  Obd2CompletenessStats completeness)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2SessionDiagnostic() when $default != null:
return $default(_that.linkKind,_that.redactedMac,_that.elmVersion,_that.protocolDigit,_that.mtu,_that.warmStart,_that.capabilityTier,_that.initTranscript,_that.pidStats,_that.connection,_that.scheduler,_that.framing,_that.fuelTierTicks,_that.fuelDowngrade,_that.sessionActiveSeconds,_that.discoveredSupported,_that.expectedReads,_that.achievedReads,_that.completenessPercent,_that.completeness);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'lk')  String? linkKind, @JsonKey(name: 'mac')  String? redactedMac, @JsonKey(name: 'ev')  String? elmVersion, @JsonKey(name: 'pd')  String? protocolDigit, @JsonKey(name: 'mtu')  int? mtu, @JsonKey(name: 'ws')  bool? warmStart, @JsonKey(name: 'ct')  String? capabilityTier, @JsonKey(name: 'tx')  List<Obd2HandshakeLine> initTranscript, @JsonKey(name: 'pid')  Map<String, Obd2PidStat> pidStats, @JsonKey(name: 'conn')  Obd2ConnectionStats connection, @JsonKey(name: 'sch')  Obd2SchedulerStats scheduler, @JsonKey(name: 'frm')  Obd2FramingStats framing, @JsonKey(name: 'ft')  Map<String, int> fuelTierTicks, @JsonKey(name: 'fd')  Obd2FuelDowngradeStats fuelDowngrade, @JsonKey(name: 'as')  int sessionActiveSeconds, @JsonKey(name: 'tri')  Map<String, String> discoveredSupported, @JsonKey(name: 'er')  int? expectedReads, @JsonKey(name: 'ar')  int? achievedReads, @JsonKey(name: 'cp')  double? completenessPercent, @JsonKey(name: 'cm')  Obd2CompletenessStats completeness)  $default,) {final _that = this;
switch (_that) {
case _Obd2SessionDiagnostic():
return $default(_that.linkKind,_that.redactedMac,_that.elmVersion,_that.protocolDigit,_that.mtu,_that.warmStart,_that.capabilityTier,_that.initTranscript,_that.pidStats,_that.connection,_that.scheduler,_that.framing,_that.fuelTierTicks,_that.fuelDowngrade,_that.sessionActiveSeconds,_that.discoveredSupported,_that.expectedReads,_that.achievedReads,_that.completenessPercent,_that.completeness);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'lk')  String? linkKind, @JsonKey(name: 'mac')  String? redactedMac, @JsonKey(name: 'ev')  String? elmVersion, @JsonKey(name: 'pd')  String? protocolDigit, @JsonKey(name: 'mtu')  int? mtu, @JsonKey(name: 'ws')  bool? warmStart, @JsonKey(name: 'ct')  String? capabilityTier, @JsonKey(name: 'tx')  List<Obd2HandshakeLine> initTranscript, @JsonKey(name: 'pid')  Map<String, Obd2PidStat> pidStats, @JsonKey(name: 'conn')  Obd2ConnectionStats connection, @JsonKey(name: 'sch')  Obd2SchedulerStats scheduler, @JsonKey(name: 'frm')  Obd2FramingStats framing, @JsonKey(name: 'ft')  Map<String, int> fuelTierTicks, @JsonKey(name: 'fd')  Obd2FuelDowngradeStats fuelDowngrade, @JsonKey(name: 'as')  int sessionActiveSeconds, @JsonKey(name: 'tri')  Map<String, String> discoveredSupported, @JsonKey(name: 'er')  int? expectedReads, @JsonKey(name: 'ar')  int? achievedReads, @JsonKey(name: 'cp')  double? completenessPercent, @JsonKey(name: 'cm')  Obd2CompletenessStats completeness)?  $default,) {final _that = this;
switch (_that) {
case _Obd2SessionDiagnostic() when $default != null:
return $default(_that.linkKind,_that.redactedMac,_that.elmVersion,_that.protocolDigit,_that.mtu,_that.warmStart,_that.capabilityTier,_that.initTranscript,_that.pidStats,_that.connection,_that.scheduler,_that.framing,_that.fuelTierTicks,_that.fuelDowngrade,_that.sessionActiveSeconds,_that.discoveredSupported,_that.expectedReads,_that.achievedReads,_that.completenessPercent,_that.completeness);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2SessionDiagnostic extends Obd2SessionDiagnostic {
  const _Obd2SessionDiagnostic({@JsonKey(name: 'lk') this.linkKind, @JsonKey(name: 'mac') this.redactedMac, @JsonKey(name: 'ev') this.elmVersion, @JsonKey(name: 'pd') this.protocolDigit, @JsonKey(name: 'mtu') this.mtu, @JsonKey(name: 'ws') this.warmStart, @JsonKey(name: 'ct') this.capabilityTier, @JsonKey(name: 'tx') final  List<Obd2HandshakeLine> initTranscript = const <Obd2HandshakeLine>[], @JsonKey(name: 'pid') final  Map<String, Obd2PidStat> pidStats = const <String, Obd2PidStat>{}, @JsonKey(name: 'conn') this.connection = const Obd2ConnectionStats(), @JsonKey(name: 'sch') this.scheduler = const Obd2SchedulerStats(), @JsonKey(name: 'frm') this.framing = const Obd2FramingStats(), @JsonKey(name: 'ft') final  Map<String, int> fuelTierTicks = const <String, int>{}, @JsonKey(name: 'fd') this.fuelDowngrade = const Obd2FuelDowngradeStats(), @JsonKey(name: 'as') this.sessionActiveSeconds = 0, @JsonKey(name: 'tri') final  Map<String, String> discoveredSupported = const <String, String>{}, @JsonKey(name: 'er') this.expectedReads, @JsonKey(name: 'ar') this.achievedReads, @JsonKey(name: 'cp') this.completenessPercent, @JsonKey(name: 'cm') this.completeness = const Obd2CompletenessStats()}): _initTranscript = initTranscript,_pidStats = pidStats,_fuelTierTicks = fuelTierTicks,_discoveredSupported = discoveredSupported,super._();
  factory _Obd2SessionDiagnostic.fromJson(Map<String, dynamic> json) => _$Obd2SessionDiagnosticFromJson(json);

/// Transport flavour that carried this session: `'ble'`, `'classic'`,
/// `'usb'`, or a future link kind. Null until [beginSession] stamps it.
@override@JsonKey(name: 'lk') final  String? linkKind;
/// Redacted adapter MAC (the existing `_redactMac` form, e.g.
/// `AA:BB:**:**:**:FF`). Null when unknown / not yet recorded.
@override@JsonKey(name: 'mac') final  String? redactedMac;
// ---- Adapter identity (filled by recordAdapterIdentity) -----------
/// ELM firmware banner version string (e.g. `'ELM327 v1.5'`). Null
/// until the handshake reads ATI.
@override@JsonKey(name: 'ev') final  String? elmVersion;
/// Auto-detected OBD protocol digit (ELM `ATDPN` reply, e.g. `'6'`
/// for ISO 15765-4 CAN 11/500). Null until detected.
@override@JsonKey(name: 'pd') final  String? protocolDigit;
/// Negotiated BLE ATT MTU (bytes). Null for classic/USB links or
/// before negotiation.
@override@JsonKey(name: 'mtu') final  int? mtu;
/// True when this session reused a warm (already-initialised) adapter
/// rather than running the full cold handshake. Null until known.
@override@JsonKey(name: 'ws') final  bool? warmStart;
/// Firmware-derived runtime capability tier name (#2465) — one of
/// `'standardOnly'` / `'oemPidsCapable'` / `'passiveCanCapable'`.
/// Wave 1 records the firmware-CLAIMED tier; Wave 2 will record the
/// value reconciled by the lazy multi-frame probe. Null until the
/// handshake reads ATI.
@override@JsonKey(name: 'ct') final  String? capabilityTier;
/// Redacted ELM init/handshake transcript, capped one-shot at
/// [maxTranscriptLines] by the collector. Oldest-first.
 final  List<Obd2HandshakeLine> _initTranscript;
/// Redacted ELM init/handshake transcript, capped one-shot at
/// [maxTranscriptLines] by the collector. Oldest-first.
@override@JsonKey(name: 'tx') List<Obd2HandshakeLine> get initTranscript {
  if (_initTranscript is EqualUnmodifiableListView) return _initTranscript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_initTranscript);
}

// ---- Per-PID outcome table (Wave 2 fills; Wave 1 leaves empty) ----
/// Map from a poll command (e.g. `'010C'`) to its 5-way outcome +
/// latency row. Bounded by the fixed set of polled PIDs.
 final  Map<String, Obd2PidStat> _pidStats;
// ---- Per-PID outcome table (Wave 2 fills; Wave 1 leaves empty) ----
/// Map from a poll command (e.g. `'010C'`) to its 5-way outcome +
/// latency row. Bounded by the fixed set of polled PIDs.
@override@JsonKey(name: 'pid') Map<String, Obd2PidStat> get pidStats {
  if (_pidStats is EqualUnmodifiableMapView) return _pidStats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_pidStats);
}

// ---- Connection lifecycle counters --------------------------------
/// Connection-lifecycle counters (attempts/successes/drops/reconnects
/// + time-to-connect reservoirs).
@override@JsonKey(name: 'conn') final  Obd2ConnectionStats connection;
// ---- Scheduler health (Wave 2 fills) ------------------------------
/// Achieved scheduler tick-rate (Hz), back-pressure skips, governor
/// demotions.
@override@JsonKey(name: 'sch') final  Obd2SchedulerStats scheduler;
// ---- Framing counters ---------------------------------------------
/// Wire-framing counters (partial frames / leftover bytes / stray
/// prompts / garbage reads).
@override@JsonKey(name: 'frm') final  Obd2FramingStats framing;
/// Per-tick fuel-resolution-tier distribution: branch tag → tick
/// count (e.g. `{'pid5E': 412, 'maf': 88, 'speedDensity': 3}`).
 final  Map<String, int> _fuelTierTicks;
/// Per-tick fuel-resolution-tier distribution: branch tag → tick
/// count (e.g. `{'pid5E': 412, 'maf': 88, 'speedDensity': 3}`).
@override@JsonKey(name: 'ft') Map<String, int> get fuelTierTicks {
  if (_fuelTierTicks is EqualUnmodifiableMapView) return _fuelTierTicks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fuelTierTicks);
}

/// Fuel-tier downgrade cause rolled up FREE from the breadcrumb
/// collector (#2469): `total` samples seen vs `suspicious` samples that
/// tripped a sanity flag (suspicious-low / 5E-vs-MAF divergent). A high
/// suspicious ratio alongside a [fuelTierTicks] skewed away from `pid5E`
/// is the downgrade-cause signature. Null/zero until Wave 2 rolls it up.
@override@JsonKey(name: 'fd') final  Obd2FuelDowngradeStats fuelDowngrade;
/// How long the session was actively polling, in whole seconds — the
/// `activeSeconds` term of the completeness expected-reads formula.
/// 0 until Wave 2 stamps it.
@override@JsonKey(name: 'as') final  int sessionActiveSeconds;
/// Discovered-supported tri-state per polled command (#2469):
/// `'supported'` / `'unsupported'` / `'unknown'`. Sourced from the
/// resolver's discovered set ∩ target set; `'unknown'` for every command
/// when discovery never ran (probe-less clone / blind session). Empty
/// until Wave 2 records it.
 final  Map<String, String> _discoveredSupported;
/// Discovered-supported tri-state per polled command (#2469):
/// `'supported'` / `'unsupported'` / `'unknown'`. Sourced from the
/// resolver's discovered set ∩ target set; `'unknown'` for every command
/// when discovery never ran (probe-less clone / blind session). Empty
/// until Wave 2 records it.
@override@JsonKey(name: 'tri') Map<String, String> get discoveredSupported {
  if (_discoveredSupported is EqualUnmodifiableMapView) return _discoveredSupported;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_discoveredSupported);
}

// ---- Completeness (Wave 2 fills; null/zero for now) ---------------
/// Σ(targetHz × activeSeconds) — the expected number of reads if the
/// scheduler had hit every target. Null until Wave 2 computes it.
@override@JsonKey(name: 'er') final  int? expectedReads;
/// Reads actually achieved this session. Null until Wave 2.
@override@JsonKey(name: 'ar') final  int? achievedReads;
/// `achievedReads / expectedReads` as a 0–100 percentage. Null until
/// Wave 2.
@override@JsonKey(name: 'cp') final  double? completenessPercent;
/// Per-tier completeness rollup (overall + 5/2/0.5/0.1 Hz tiers +
/// active duty cycle + emit-index gaps). Empty default until Wave 2
/// computes it via `summariseObd2Completeness`.
@override@JsonKey(name: 'cm') final  Obd2CompletenessStats completeness;

/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2SessionDiagnosticCopyWith<_Obd2SessionDiagnostic> get copyWith => __$Obd2SessionDiagnosticCopyWithImpl<_Obd2SessionDiagnostic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2SessionDiagnosticToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2SessionDiagnostic&&(identical(other.linkKind, linkKind) || other.linkKind == linkKind)&&(identical(other.redactedMac, redactedMac) || other.redactedMac == redactedMac)&&(identical(other.elmVersion, elmVersion) || other.elmVersion == elmVersion)&&(identical(other.protocolDigit, protocolDigit) || other.protocolDigit == protocolDigit)&&(identical(other.mtu, mtu) || other.mtu == mtu)&&(identical(other.warmStart, warmStart) || other.warmStart == warmStart)&&(identical(other.capabilityTier, capabilityTier) || other.capabilityTier == capabilityTier)&&const DeepCollectionEquality().equals(other._initTranscript, _initTranscript)&&const DeepCollectionEquality().equals(other._pidStats, _pidStats)&&(identical(other.connection, connection) || other.connection == connection)&&(identical(other.scheduler, scheduler) || other.scheduler == scheduler)&&(identical(other.framing, framing) || other.framing == framing)&&const DeepCollectionEquality().equals(other._fuelTierTicks, _fuelTierTicks)&&(identical(other.fuelDowngrade, fuelDowngrade) || other.fuelDowngrade == fuelDowngrade)&&(identical(other.sessionActiveSeconds, sessionActiveSeconds) || other.sessionActiveSeconds == sessionActiveSeconds)&&const DeepCollectionEquality().equals(other._discoveredSupported, _discoveredSupported)&&(identical(other.expectedReads, expectedReads) || other.expectedReads == expectedReads)&&(identical(other.achievedReads, achievedReads) || other.achievedReads == achievedReads)&&(identical(other.completenessPercent, completenessPercent) || other.completenessPercent == completenessPercent)&&(identical(other.completeness, completeness) || other.completeness == completeness));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,linkKind,redactedMac,elmVersion,protocolDigit,mtu,warmStart,capabilityTier,const DeepCollectionEquality().hash(_initTranscript),const DeepCollectionEquality().hash(_pidStats),connection,scheduler,framing,const DeepCollectionEquality().hash(_fuelTierTicks),fuelDowngrade,sessionActiveSeconds,const DeepCollectionEquality().hash(_discoveredSupported),expectedReads,achievedReads,completenessPercent,completeness]);

@override
String toString() {
  return 'Obd2SessionDiagnostic(linkKind: $linkKind, redactedMac: $redactedMac, elmVersion: $elmVersion, protocolDigit: $protocolDigit, mtu: $mtu, warmStart: $warmStart, capabilityTier: $capabilityTier, initTranscript: $initTranscript, pidStats: $pidStats, connection: $connection, scheduler: $scheduler, framing: $framing, fuelTierTicks: $fuelTierTicks, fuelDowngrade: $fuelDowngrade, sessionActiveSeconds: $sessionActiveSeconds, discoveredSupported: $discoveredSupported, expectedReads: $expectedReads, achievedReads: $achievedReads, completenessPercent: $completenessPercent, completeness: $completeness)';
}


}

/// @nodoc
abstract mixin class _$Obd2SessionDiagnosticCopyWith<$Res> implements $Obd2SessionDiagnosticCopyWith<$Res> {
  factory _$Obd2SessionDiagnosticCopyWith(_Obd2SessionDiagnostic value, $Res Function(_Obd2SessionDiagnostic) _then) = __$Obd2SessionDiagnosticCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'lk') String? linkKind,@JsonKey(name: 'mac') String? redactedMac,@JsonKey(name: 'ev') String? elmVersion,@JsonKey(name: 'pd') String? protocolDigit,@JsonKey(name: 'mtu') int? mtu,@JsonKey(name: 'ws') bool? warmStart,@JsonKey(name: 'ct') String? capabilityTier,@JsonKey(name: 'tx') List<Obd2HandshakeLine> initTranscript,@JsonKey(name: 'pid') Map<String, Obd2PidStat> pidStats,@JsonKey(name: 'conn') Obd2ConnectionStats connection,@JsonKey(name: 'sch') Obd2SchedulerStats scheduler,@JsonKey(name: 'frm') Obd2FramingStats framing,@JsonKey(name: 'ft') Map<String, int> fuelTierTicks,@JsonKey(name: 'fd') Obd2FuelDowngradeStats fuelDowngrade,@JsonKey(name: 'as') int sessionActiveSeconds,@JsonKey(name: 'tri') Map<String, String> discoveredSupported,@JsonKey(name: 'er') int? expectedReads,@JsonKey(name: 'ar') int? achievedReads,@JsonKey(name: 'cp') double? completenessPercent,@JsonKey(name: 'cm') Obd2CompletenessStats completeness
});


@override $Obd2ConnectionStatsCopyWith<$Res> get connection;@override $Obd2SchedulerStatsCopyWith<$Res> get scheduler;@override $Obd2FramingStatsCopyWith<$Res> get framing;@override $Obd2FuelDowngradeStatsCopyWith<$Res> get fuelDowngrade;@override $Obd2CompletenessStatsCopyWith<$Res> get completeness;

}
/// @nodoc
class __$Obd2SessionDiagnosticCopyWithImpl<$Res>
    implements _$Obd2SessionDiagnosticCopyWith<$Res> {
  __$Obd2SessionDiagnosticCopyWithImpl(this._self, this._then);

  final _Obd2SessionDiagnostic _self;
  final $Res Function(_Obd2SessionDiagnostic) _then;

/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? linkKind = freezed,Object? redactedMac = freezed,Object? elmVersion = freezed,Object? protocolDigit = freezed,Object? mtu = freezed,Object? warmStart = freezed,Object? capabilityTier = freezed,Object? initTranscript = null,Object? pidStats = null,Object? connection = null,Object? scheduler = null,Object? framing = null,Object? fuelTierTicks = null,Object? fuelDowngrade = null,Object? sessionActiveSeconds = null,Object? discoveredSupported = null,Object? expectedReads = freezed,Object? achievedReads = freezed,Object? completenessPercent = freezed,Object? completeness = null,}) {
  return _then(_Obd2SessionDiagnostic(
linkKind: freezed == linkKind ? _self.linkKind : linkKind // ignore: cast_nullable_to_non_nullable
as String?,redactedMac: freezed == redactedMac ? _self.redactedMac : redactedMac // ignore: cast_nullable_to_non_nullable
as String?,elmVersion: freezed == elmVersion ? _self.elmVersion : elmVersion // ignore: cast_nullable_to_non_nullable
as String?,protocolDigit: freezed == protocolDigit ? _self.protocolDigit : protocolDigit // ignore: cast_nullable_to_non_nullable
as String?,mtu: freezed == mtu ? _self.mtu : mtu // ignore: cast_nullable_to_non_nullable
as int?,warmStart: freezed == warmStart ? _self.warmStart : warmStart // ignore: cast_nullable_to_non_nullable
as bool?,capabilityTier: freezed == capabilityTier ? _self.capabilityTier : capabilityTier // ignore: cast_nullable_to_non_nullable
as String?,initTranscript: null == initTranscript ? _self._initTranscript : initTranscript // ignore: cast_nullable_to_non_nullable
as List<Obd2HandshakeLine>,pidStats: null == pidStats ? _self._pidStats : pidStats // ignore: cast_nullable_to_non_nullable
as Map<String, Obd2PidStat>,connection: null == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as Obd2ConnectionStats,scheduler: null == scheduler ? _self.scheduler : scheduler // ignore: cast_nullable_to_non_nullable
as Obd2SchedulerStats,framing: null == framing ? _self.framing : framing // ignore: cast_nullable_to_non_nullable
as Obd2FramingStats,fuelTierTicks: null == fuelTierTicks ? _self._fuelTierTicks : fuelTierTicks // ignore: cast_nullable_to_non_nullable
as Map<String, int>,fuelDowngrade: null == fuelDowngrade ? _self.fuelDowngrade : fuelDowngrade // ignore: cast_nullable_to_non_nullable
as Obd2FuelDowngradeStats,sessionActiveSeconds: null == sessionActiveSeconds ? _self.sessionActiveSeconds : sessionActiveSeconds // ignore: cast_nullable_to_non_nullable
as int,discoveredSupported: null == discoveredSupported ? _self._discoveredSupported : discoveredSupported // ignore: cast_nullable_to_non_nullable
as Map<String, String>,expectedReads: freezed == expectedReads ? _self.expectedReads : expectedReads // ignore: cast_nullable_to_non_nullable
as int?,achievedReads: freezed == achievedReads ? _self.achievedReads : achievedReads // ignore: cast_nullable_to_non_nullable
as int?,completenessPercent: freezed == completenessPercent ? _self.completenessPercent : completenessPercent // ignore: cast_nullable_to_non_nullable
as double?,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as Obd2CompletenessStats,
  ));
}

/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2ConnectionStatsCopyWith<$Res> get connection {
  
  return $Obd2ConnectionStatsCopyWith<$Res>(_self.connection, (value) {
    return _then(_self.copyWith(connection: value));
  });
}/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2SchedulerStatsCopyWith<$Res> get scheduler {
  
  return $Obd2SchedulerStatsCopyWith<$Res>(_self.scheduler, (value) {
    return _then(_self.copyWith(scheduler: value));
  });
}/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2FramingStatsCopyWith<$Res> get framing {
  
  return $Obd2FramingStatsCopyWith<$Res>(_self.framing, (value) {
    return _then(_self.copyWith(framing: value));
  });
}/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2FuelDowngradeStatsCopyWith<$Res> get fuelDowngrade {
  
  return $Obd2FuelDowngradeStatsCopyWith<$Res>(_self.fuelDowngrade, (value) {
    return _then(_self.copyWith(fuelDowngrade: value));
  });
}/// Create a copy of Obd2SessionDiagnostic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Obd2CompletenessStatsCopyWith<$Res> get completeness {
  
  return $Obd2CompletenessStatsCopyWith<$Res>(_self.completeness, (value) {
    return _then(_self.copyWith(completeness: value));
  });
}
}


/// @nodoc
mixin _$Obd2HandshakeLine {

/// The command sent (e.g. `'ATZ'`, `'0100'`). Trimmed.
@JsonKey(name: 'c') String get cmd;/// The redacted reply text. Trimmed; PII (VIN bytes) scrubbed by the
/// caller before it reaches here.
@JsonKey(name: 'r') String get response;/// Round-trip latency in milliseconds.
@JsonKey(name: 'l') int get latencyMs;
/// Create a copy of Obd2HandshakeLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2HandshakeLineCopyWith<Obd2HandshakeLine> get copyWith => _$Obd2HandshakeLineCopyWithImpl<Obd2HandshakeLine>(this as Obd2HandshakeLine, _$identity);

  /// Serializes this Obd2HandshakeLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2HandshakeLine&&(identical(other.cmd, cmd) || other.cmd == cmd)&&(identical(other.response, response) || other.response == response)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cmd,response,latencyMs);

@override
String toString() {
  return 'Obd2HandshakeLine(cmd: $cmd, response: $response, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class $Obd2HandshakeLineCopyWith<$Res>  {
  factory $Obd2HandshakeLineCopyWith(Obd2HandshakeLine value, $Res Function(Obd2HandshakeLine) _then) = _$Obd2HandshakeLineCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'c') String cmd,@JsonKey(name: 'r') String response,@JsonKey(name: 'l') int latencyMs
});




}
/// @nodoc
class _$Obd2HandshakeLineCopyWithImpl<$Res>
    implements $Obd2HandshakeLineCopyWith<$Res> {
  _$Obd2HandshakeLineCopyWithImpl(this._self, this._then);

  final Obd2HandshakeLine _self;
  final $Res Function(Obd2HandshakeLine) _then;

/// Create a copy of Obd2HandshakeLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cmd = null,Object? response = null,Object? latencyMs = null,}) {
  return _then(_self.copyWith(
cmd: null == cmd ? _self.cmd : cmd // ignore: cast_nullable_to_non_nullable
as String,response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2HandshakeLine].
extension Obd2HandshakeLinePatterns on Obd2HandshakeLine {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2HandshakeLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2HandshakeLine() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2HandshakeLine value)  $default,){
final _that = this;
switch (_that) {
case _Obd2HandshakeLine():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2HandshakeLine value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2HandshakeLine() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'c')  String cmd, @JsonKey(name: 'r')  String response, @JsonKey(name: 'l')  int latencyMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2HandshakeLine() when $default != null:
return $default(_that.cmd,_that.response,_that.latencyMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'c')  String cmd, @JsonKey(name: 'r')  String response, @JsonKey(name: 'l')  int latencyMs)  $default,) {final _that = this;
switch (_that) {
case _Obd2HandshakeLine():
return $default(_that.cmd,_that.response,_that.latencyMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'c')  String cmd, @JsonKey(name: 'r')  String response, @JsonKey(name: 'l')  int latencyMs)?  $default,) {final _that = this;
switch (_that) {
case _Obd2HandshakeLine() when $default != null:
return $default(_that.cmd,_that.response,_that.latencyMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2HandshakeLine implements Obd2HandshakeLine {
  const _Obd2HandshakeLine({@JsonKey(name: 'c') required this.cmd, @JsonKey(name: 'r') required this.response, @JsonKey(name: 'l') required this.latencyMs});
  factory _Obd2HandshakeLine.fromJson(Map<String, dynamic> json) => _$Obd2HandshakeLineFromJson(json);

/// The command sent (e.g. `'ATZ'`, `'0100'`). Trimmed.
@override@JsonKey(name: 'c') final  String cmd;
/// The redacted reply text. Trimmed; PII (VIN bytes) scrubbed by the
/// caller before it reaches here.
@override@JsonKey(name: 'r') final  String response;
/// Round-trip latency in milliseconds.
@override@JsonKey(name: 'l') final  int latencyMs;

/// Create a copy of Obd2HandshakeLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2HandshakeLineCopyWith<_Obd2HandshakeLine> get copyWith => __$Obd2HandshakeLineCopyWithImpl<_Obd2HandshakeLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2HandshakeLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2HandshakeLine&&(identical(other.cmd, cmd) || other.cmd == cmd)&&(identical(other.response, response) || other.response == response)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cmd,response,latencyMs);

@override
String toString() {
  return 'Obd2HandshakeLine(cmd: $cmd, response: $response, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class _$Obd2HandshakeLineCopyWith<$Res> implements $Obd2HandshakeLineCopyWith<$Res> {
  factory _$Obd2HandshakeLineCopyWith(_Obd2HandshakeLine value, $Res Function(_Obd2HandshakeLine) _then) = __$Obd2HandshakeLineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'c') String cmd,@JsonKey(name: 'r') String response,@JsonKey(name: 'l') int latencyMs
});




}
/// @nodoc
class __$Obd2HandshakeLineCopyWithImpl<$Res>
    implements _$Obd2HandshakeLineCopyWith<$Res> {
  __$Obd2HandshakeLineCopyWithImpl(this._self, this._then);

  final _Obd2HandshakeLine _self;
  final $Res Function(_Obd2HandshakeLine) _then;

/// Create a copy of Obd2HandshakeLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cmd = null,Object? response = null,Object? latencyMs = null,}) {
  return _then(_Obd2HandshakeLine(
cmd: null == cmd ? _self.cmd : cmd // ignore: cast_nullable_to_non_nullable
as String,response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Obd2PidStat {

/// How many times this PID was dispatched.
@JsonKey(name: 'p') int get polled;/// Replies classified [ResponseClass.ok].
@JsonKey(name: 'ok') int get ok;/// Replies classified [ResponseClass.noData].
@JsonKey(name: 'nd') int get noData;/// Reads that elapsed with no reply (caller-set timeout).
@JsonKey(name: 'to') int get timeout;/// Replies in any error/garbage bucket (bufferFull/canError/
/// unrecognized/garbage rolled up).
@JsonKey(name: 'er') int get error;/// Median (p50) round-trip latency in ms across this PID's reads.
@JsonKey(name: 'p50') int get latencyP50Ms;/// 95th-percentile round-trip latency in ms.
@JsonKey(name: 'p95') int get latencyP95Ms;/// Configured target refresh rate (Hz) the scheduler aims for this PID.
/// 0 when the dispatch tee didn't carry a target (e.g. a one-off raw
/// read outside the scheduler).
@JsonKey(name: 'th') double get targetHz;/// Achieved effective refresh rate (Hz) = `ok / sessionActiveSeconds`,
/// filled by `summariseObd2Completeness`. 0 until completeness runs.
@JsonKey(name: 'eh') double get effectiveHz;/// Cadence tier name (`'dynamics'`/`'mixture'`/`'slowCorrection'`/
/// `'thermalContext'`) carried by the dispatch tee. Null for un-tiered
/// raw reads.
@JsonKey(name: 'ti') String? get tier;/// Consecutive transport failures at the last result for this PID — the
/// scheduler's #2379 backoff streak. 0 when the last read succeeded.
@JsonKey(name: 'cf') int get consecutiveFailures;/// True when this PID was in the scheduler's backed-off state at the
/// last result (failed ≥ the backoff threshold in a row, polled at the
/// slow ≈1/30 s rate). Persisted so a mostly-NO-DATA PID is visible.
@JsonKey(name: 'bo') bool get backedOff;
/// Create a copy of Obd2PidStat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2PidStatCopyWith<Obd2PidStat> get copyWith => _$Obd2PidStatCopyWithImpl<Obd2PidStat>(this as Obd2PidStat, _$identity);

  /// Serializes this Obd2PidStat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2PidStat&&(identical(other.polled, polled) || other.polled == polled)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.noData, noData) || other.noData == noData)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.error, error) || other.error == error)&&(identical(other.latencyP50Ms, latencyP50Ms) || other.latencyP50Ms == latencyP50Ms)&&(identical(other.latencyP95Ms, latencyP95Ms) || other.latencyP95Ms == latencyP95Ms)&&(identical(other.targetHz, targetHz) || other.targetHz == targetHz)&&(identical(other.effectiveHz, effectiveHz) || other.effectiveHz == effectiveHz)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.consecutiveFailures, consecutiveFailures) || other.consecutiveFailures == consecutiveFailures)&&(identical(other.backedOff, backedOff) || other.backedOff == backedOff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,polled,ok,noData,timeout,error,latencyP50Ms,latencyP95Ms,targetHz,effectiveHz,tier,consecutiveFailures,backedOff);

@override
String toString() {
  return 'Obd2PidStat(polled: $polled, ok: $ok, noData: $noData, timeout: $timeout, error: $error, latencyP50Ms: $latencyP50Ms, latencyP95Ms: $latencyP95Ms, targetHz: $targetHz, effectiveHz: $effectiveHz, tier: $tier, consecutiveFailures: $consecutiveFailures, backedOff: $backedOff)';
}


}

/// @nodoc
abstract mixin class $Obd2PidStatCopyWith<$Res>  {
  factory $Obd2PidStatCopyWith(Obd2PidStat value, $Res Function(Obd2PidStat) _then) = _$Obd2PidStatCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'p') int polled,@JsonKey(name: 'ok') int ok,@JsonKey(name: 'nd') int noData,@JsonKey(name: 'to') int timeout,@JsonKey(name: 'er') int error,@JsonKey(name: 'p50') int latencyP50Ms,@JsonKey(name: 'p95') int latencyP95Ms,@JsonKey(name: 'th') double targetHz,@JsonKey(name: 'eh') double effectiveHz,@JsonKey(name: 'ti') String? tier,@JsonKey(name: 'cf') int consecutiveFailures,@JsonKey(name: 'bo') bool backedOff
});




}
/// @nodoc
class _$Obd2PidStatCopyWithImpl<$Res>
    implements $Obd2PidStatCopyWith<$Res> {
  _$Obd2PidStatCopyWithImpl(this._self, this._then);

  final Obd2PidStat _self;
  final $Res Function(Obd2PidStat) _then;

/// Create a copy of Obd2PidStat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? polled = null,Object? ok = null,Object? noData = null,Object? timeout = null,Object? error = null,Object? latencyP50Ms = null,Object? latencyP95Ms = null,Object? targetHz = null,Object? effectiveHz = null,Object? tier = freezed,Object? consecutiveFailures = null,Object? backedOff = null,}) {
  return _then(_self.copyWith(
polled: null == polled ? _self.polled : polled // ignore: cast_nullable_to_non_nullable
as int,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as int,noData: null == noData ? _self.noData : noData // ignore: cast_nullable_to_non_nullable
as int,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as int,latencyP50Ms: null == latencyP50Ms ? _self.latencyP50Ms : latencyP50Ms // ignore: cast_nullable_to_non_nullable
as int,latencyP95Ms: null == latencyP95Ms ? _self.latencyP95Ms : latencyP95Ms // ignore: cast_nullable_to_non_nullable
as int,targetHz: null == targetHz ? _self.targetHz : targetHz // ignore: cast_nullable_to_non_nullable
as double,effectiveHz: null == effectiveHz ? _self.effectiveHz : effectiveHz // ignore: cast_nullable_to_non_nullable
as double,tier: freezed == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String?,consecutiveFailures: null == consecutiveFailures ? _self.consecutiveFailures : consecutiveFailures // ignore: cast_nullable_to_non_nullable
as int,backedOff: null == backedOff ? _self.backedOff : backedOff // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2PidStat].
extension Obd2PidStatPatterns on Obd2PidStat {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2PidStat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2PidStat() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2PidStat value)  $default,){
final _that = this;
switch (_that) {
case _Obd2PidStat():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2PidStat value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2PidStat() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'p')  int polled, @JsonKey(name: 'ok')  int ok, @JsonKey(name: 'nd')  int noData, @JsonKey(name: 'to')  int timeout, @JsonKey(name: 'er')  int error, @JsonKey(name: 'p50')  int latencyP50Ms, @JsonKey(name: 'p95')  int latencyP95Ms, @JsonKey(name: 'th')  double targetHz, @JsonKey(name: 'eh')  double effectiveHz, @JsonKey(name: 'ti')  String? tier, @JsonKey(name: 'cf')  int consecutiveFailures, @JsonKey(name: 'bo')  bool backedOff)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2PidStat() when $default != null:
return $default(_that.polled,_that.ok,_that.noData,_that.timeout,_that.error,_that.latencyP50Ms,_that.latencyP95Ms,_that.targetHz,_that.effectiveHz,_that.tier,_that.consecutiveFailures,_that.backedOff);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'p')  int polled, @JsonKey(name: 'ok')  int ok, @JsonKey(name: 'nd')  int noData, @JsonKey(name: 'to')  int timeout, @JsonKey(name: 'er')  int error, @JsonKey(name: 'p50')  int latencyP50Ms, @JsonKey(name: 'p95')  int latencyP95Ms, @JsonKey(name: 'th')  double targetHz, @JsonKey(name: 'eh')  double effectiveHz, @JsonKey(name: 'ti')  String? tier, @JsonKey(name: 'cf')  int consecutiveFailures, @JsonKey(name: 'bo')  bool backedOff)  $default,) {final _that = this;
switch (_that) {
case _Obd2PidStat():
return $default(_that.polled,_that.ok,_that.noData,_that.timeout,_that.error,_that.latencyP50Ms,_that.latencyP95Ms,_that.targetHz,_that.effectiveHz,_that.tier,_that.consecutiveFailures,_that.backedOff);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'p')  int polled, @JsonKey(name: 'ok')  int ok, @JsonKey(name: 'nd')  int noData, @JsonKey(name: 'to')  int timeout, @JsonKey(name: 'er')  int error, @JsonKey(name: 'p50')  int latencyP50Ms, @JsonKey(name: 'p95')  int latencyP95Ms, @JsonKey(name: 'th')  double targetHz, @JsonKey(name: 'eh')  double effectiveHz, @JsonKey(name: 'ti')  String? tier, @JsonKey(name: 'cf')  int consecutiveFailures, @JsonKey(name: 'bo')  bool backedOff)?  $default,) {final _that = this;
switch (_that) {
case _Obd2PidStat() when $default != null:
return $default(_that.polled,_that.ok,_that.noData,_that.timeout,_that.error,_that.latencyP50Ms,_that.latencyP95Ms,_that.targetHz,_that.effectiveHz,_that.tier,_that.consecutiveFailures,_that.backedOff);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2PidStat extends Obd2PidStat {
  const _Obd2PidStat({@JsonKey(name: 'p') this.polled = 0, @JsonKey(name: 'ok') this.ok = 0, @JsonKey(name: 'nd') this.noData = 0, @JsonKey(name: 'to') this.timeout = 0, @JsonKey(name: 'er') this.error = 0, @JsonKey(name: 'p50') this.latencyP50Ms = 0, @JsonKey(name: 'p95') this.latencyP95Ms = 0, @JsonKey(name: 'th') this.targetHz = 0.0, @JsonKey(name: 'eh') this.effectiveHz = 0.0, @JsonKey(name: 'ti') this.tier, @JsonKey(name: 'cf') this.consecutiveFailures = 0, @JsonKey(name: 'bo') this.backedOff = false}): super._();
  factory _Obd2PidStat.fromJson(Map<String, dynamic> json) => _$Obd2PidStatFromJson(json);

/// How many times this PID was dispatched.
@override@JsonKey(name: 'p') final  int polled;
/// Replies classified [ResponseClass.ok].
@override@JsonKey(name: 'ok') final  int ok;
/// Replies classified [ResponseClass.noData].
@override@JsonKey(name: 'nd') final  int noData;
/// Reads that elapsed with no reply (caller-set timeout).
@override@JsonKey(name: 'to') final  int timeout;
/// Replies in any error/garbage bucket (bufferFull/canError/
/// unrecognized/garbage rolled up).
@override@JsonKey(name: 'er') final  int error;
/// Median (p50) round-trip latency in ms across this PID's reads.
@override@JsonKey(name: 'p50') final  int latencyP50Ms;
/// 95th-percentile round-trip latency in ms.
@override@JsonKey(name: 'p95') final  int latencyP95Ms;
/// Configured target refresh rate (Hz) the scheduler aims for this PID.
/// 0 when the dispatch tee didn't carry a target (e.g. a one-off raw
/// read outside the scheduler).
@override@JsonKey(name: 'th') final  double targetHz;
/// Achieved effective refresh rate (Hz) = `ok / sessionActiveSeconds`,
/// filled by `summariseObd2Completeness`. 0 until completeness runs.
@override@JsonKey(name: 'eh') final  double effectiveHz;
/// Cadence tier name (`'dynamics'`/`'mixture'`/`'slowCorrection'`/
/// `'thermalContext'`) carried by the dispatch tee. Null for un-tiered
/// raw reads.
@override@JsonKey(name: 'ti') final  String? tier;
/// Consecutive transport failures at the last result for this PID — the
/// scheduler's #2379 backoff streak. 0 when the last read succeeded.
@override@JsonKey(name: 'cf') final  int consecutiveFailures;
/// True when this PID was in the scheduler's backed-off state at the
/// last result (failed ≥ the backoff threshold in a row, polled at the
/// slow ≈1/30 s rate). Persisted so a mostly-NO-DATA PID is visible.
@override@JsonKey(name: 'bo') final  bool backedOff;

/// Create a copy of Obd2PidStat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2PidStatCopyWith<_Obd2PidStat> get copyWith => __$Obd2PidStatCopyWithImpl<_Obd2PidStat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2PidStatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2PidStat&&(identical(other.polled, polled) || other.polled == polled)&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.noData, noData) || other.noData == noData)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.error, error) || other.error == error)&&(identical(other.latencyP50Ms, latencyP50Ms) || other.latencyP50Ms == latencyP50Ms)&&(identical(other.latencyP95Ms, latencyP95Ms) || other.latencyP95Ms == latencyP95Ms)&&(identical(other.targetHz, targetHz) || other.targetHz == targetHz)&&(identical(other.effectiveHz, effectiveHz) || other.effectiveHz == effectiveHz)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.consecutiveFailures, consecutiveFailures) || other.consecutiveFailures == consecutiveFailures)&&(identical(other.backedOff, backedOff) || other.backedOff == backedOff));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,polled,ok,noData,timeout,error,latencyP50Ms,latencyP95Ms,targetHz,effectiveHz,tier,consecutiveFailures,backedOff);

@override
String toString() {
  return 'Obd2PidStat(polled: $polled, ok: $ok, noData: $noData, timeout: $timeout, error: $error, latencyP50Ms: $latencyP50Ms, latencyP95Ms: $latencyP95Ms, targetHz: $targetHz, effectiveHz: $effectiveHz, tier: $tier, consecutiveFailures: $consecutiveFailures, backedOff: $backedOff)';
}


}

/// @nodoc
abstract mixin class _$Obd2PidStatCopyWith<$Res> implements $Obd2PidStatCopyWith<$Res> {
  factory _$Obd2PidStatCopyWith(_Obd2PidStat value, $Res Function(_Obd2PidStat) _then) = __$Obd2PidStatCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'p') int polled,@JsonKey(name: 'ok') int ok,@JsonKey(name: 'nd') int noData,@JsonKey(name: 'to') int timeout,@JsonKey(name: 'er') int error,@JsonKey(name: 'p50') int latencyP50Ms,@JsonKey(name: 'p95') int latencyP95Ms,@JsonKey(name: 'th') double targetHz,@JsonKey(name: 'eh') double effectiveHz,@JsonKey(name: 'ti') String? tier,@JsonKey(name: 'cf') int consecutiveFailures,@JsonKey(name: 'bo') bool backedOff
});




}
/// @nodoc
class __$Obd2PidStatCopyWithImpl<$Res>
    implements _$Obd2PidStatCopyWith<$Res> {
  __$Obd2PidStatCopyWithImpl(this._self, this._then);

  final _Obd2PidStat _self;
  final $Res Function(_Obd2PidStat) _then;

/// Create a copy of Obd2PidStat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? polled = null,Object? ok = null,Object? noData = null,Object? timeout = null,Object? error = null,Object? latencyP50Ms = null,Object? latencyP95Ms = null,Object? targetHz = null,Object? effectiveHz = null,Object? tier = freezed,Object? consecutiveFailures = null,Object? backedOff = null,}) {
  return _then(_Obd2PidStat(
polled: null == polled ? _self.polled : polled // ignore: cast_nullable_to_non_nullable
as int,ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as int,noData: null == noData ? _self.noData : noData // ignore: cast_nullable_to_non_nullable
as int,timeout: null == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as int,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as int,latencyP50Ms: null == latencyP50Ms ? _self.latencyP50Ms : latencyP50Ms // ignore: cast_nullable_to_non_nullable
as int,latencyP95Ms: null == latencyP95Ms ? _self.latencyP95Ms : latencyP95Ms // ignore: cast_nullable_to_non_nullable
as int,targetHz: null == targetHz ? _self.targetHz : targetHz // ignore: cast_nullable_to_non_nullable
as double,effectiveHz: null == effectiveHz ? _self.effectiveHz : effectiveHz // ignore: cast_nullable_to_non_nullable
as double,tier: freezed == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String?,consecutiveFailures: null == consecutiveFailures ? _self.consecutiveFailures : consecutiveFailures // ignore: cast_nullable_to_non_nullable
as int,backedOff: null == backedOff ? _self.backedOff : backedOff // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Obd2ConnectionStats {

/// Total connection attempts (cold + reconnect).
@JsonKey(name: 'at') int get attempts;/// Attempts that established a working link.
@JsonKey(name: 'su') int get successes;/// Map from a failure reason tag to its count (e.g.
/// `{'gattTimeout': 2, 'noElm': 1}`). Bounded by the small set of
/// known reasons.
@JsonKey(name: 'fr') Map<String, int> get failuresByReason;/// Detected mid-session link drops.
@JsonKey(name: 'dr') int get drops;/// Reconnects that recovered without the user seeing a disconnect.
@JsonKey(name: 'sr') int get silentReconnects;/// Reconnects that surfaced a visible disconnect first.
@JsonKey(name: 'vr') int get visibleReconnects;/// Time-to-connect reservoir percentiles (ms) for cold connects.
@JsonKey(name: 'tc') int? get timeToConnectP50Ms;@JsonKey(name: 'tcp95') int? get timeToConnectP95Ms;/// Time-to-reconnect reservoir percentiles (ms).
@JsonKey(name: 'rc') int? get timeToReconnectP50Ms;@JsonKey(name: 'rcp95') int? get timeToReconnectP95Ms;
/// Create a copy of Obd2ConnectionStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2ConnectionStatsCopyWith<Obd2ConnectionStats> get copyWith => _$Obd2ConnectionStatsCopyWithImpl<Obd2ConnectionStats>(this as Obd2ConnectionStats, _$identity);

  /// Serializes this Obd2ConnectionStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2ConnectionStats&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.successes, successes) || other.successes == successes)&&const DeepCollectionEquality().equals(other.failuresByReason, failuresByReason)&&(identical(other.drops, drops) || other.drops == drops)&&(identical(other.silentReconnects, silentReconnects) || other.silentReconnects == silentReconnects)&&(identical(other.visibleReconnects, visibleReconnects) || other.visibleReconnects == visibleReconnects)&&(identical(other.timeToConnectP50Ms, timeToConnectP50Ms) || other.timeToConnectP50Ms == timeToConnectP50Ms)&&(identical(other.timeToConnectP95Ms, timeToConnectP95Ms) || other.timeToConnectP95Ms == timeToConnectP95Ms)&&(identical(other.timeToReconnectP50Ms, timeToReconnectP50Ms) || other.timeToReconnectP50Ms == timeToReconnectP50Ms)&&(identical(other.timeToReconnectP95Ms, timeToReconnectP95Ms) || other.timeToReconnectP95Ms == timeToReconnectP95Ms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attempts,successes,const DeepCollectionEquality().hash(failuresByReason),drops,silentReconnects,visibleReconnects,timeToConnectP50Ms,timeToConnectP95Ms,timeToReconnectP50Ms,timeToReconnectP95Ms);

@override
String toString() {
  return 'Obd2ConnectionStats(attempts: $attempts, successes: $successes, failuresByReason: $failuresByReason, drops: $drops, silentReconnects: $silentReconnects, visibleReconnects: $visibleReconnects, timeToConnectP50Ms: $timeToConnectP50Ms, timeToConnectP95Ms: $timeToConnectP95Ms, timeToReconnectP50Ms: $timeToReconnectP50Ms, timeToReconnectP95Ms: $timeToReconnectP95Ms)';
}


}

/// @nodoc
abstract mixin class $Obd2ConnectionStatsCopyWith<$Res>  {
  factory $Obd2ConnectionStatsCopyWith(Obd2ConnectionStats value, $Res Function(Obd2ConnectionStats) _then) = _$Obd2ConnectionStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'at') int attempts,@JsonKey(name: 'su') int successes,@JsonKey(name: 'fr') Map<String, int> failuresByReason,@JsonKey(name: 'dr') int drops,@JsonKey(name: 'sr') int silentReconnects,@JsonKey(name: 'vr') int visibleReconnects,@JsonKey(name: 'tc') int? timeToConnectP50Ms,@JsonKey(name: 'tcp95') int? timeToConnectP95Ms,@JsonKey(name: 'rc') int? timeToReconnectP50Ms,@JsonKey(name: 'rcp95') int? timeToReconnectP95Ms
});




}
/// @nodoc
class _$Obd2ConnectionStatsCopyWithImpl<$Res>
    implements $Obd2ConnectionStatsCopyWith<$Res> {
  _$Obd2ConnectionStatsCopyWithImpl(this._self, this._then);

  final Obd2ConnectionStats _self;
  final $Res Function(Obd2ConnectionStats) _then;

/// Create a copy of Obd2ConnectionStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attempts = null,Object? successes = null,Object? failuresByReason = null,Object? drops = null,Object? silentReconnects = null,Object? visibleReconnects = null,Object? timeToConnectP50Ms = freezed,Object? timeToConnectP95Ms = freezed,Object? timeToReconnectP50Ms = freezed,Object? timeToReconnectP95Ms = freezed,}) {
  return _then(_self.copyWith(
attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,successes: null == successes ? _self.successes : successes // ignore: cast_nullable_to_non_nullable
as int,failuresByReason: null == failuresByReason ? _self.failuresByReason : failuresByReason // ignore: cast_nullable_to_non_nullable
as Map<String, int>,drops: null == drops ? _self.drops : drops // ignore: cast_nullable_to_non_nullable
as int,silentReconnects: null == silentReconnects ? _self.silentReconnects : silentReconnects // ignore: cast_nullable_to_non_nullable
as int,visibleReconnects: null == visibleReconnects ? _self.visibleReconnects : visibleReconnects // ignore: cast_nullable_to_non_nullable
as int,timeToConnectP50Ms: freezed == timeToConnectP50Ms ? _self.timeToConnectP50Ms : timeToConnectP50Ms // ignore: cast_nullable_to_non_nullable
as int?,timeToConnectP95Ms: freezed == timeToConnectP95Ms ? _self.timeToConnectP95Ms : timeToConnectP95Ms // ignore: cast_nullable_to_non_nullable
as int?,timeToReconnectP50Ms: freezed == timeToReconnectP50Ms ? _self.timeToReconnectP50Ms : timeToReconnectP50Ms // ignore: cast_nullable_to_non_nullable
as int?,timeToReconnectP95Ms: freezed == timeToReconnectP95Ms ? _self.timeToReconnectP95Ms : timeToReconnectP95Ms // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2ConnectionStats].
extension Obd2ConnectionStatsPatterns on Obd2ConnectionStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2ConnectionStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2ConnectionStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2ConnectionStats value)  $default,){
final _that = this;
switch (_that) {
case _Obd2ConnectionStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2ConnectionStats value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2ConnectionStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'at')  int attempts, @JsonKey(name: 'su')  int successes, @JsonKey(name: 'fr')  Map<String, int> failuresByReason, @JsonKey(name: 'dr')  int drops, @JsonKey(name: 'sr')  int silentReconnects, @JsonKey(name: 'vr')  int visibleReconnects, @JsonKey(name: 'tc')  int? timeToConnectP50Ms, @JsonKey(name: 'tcp95')  int? timeToConnectP95Ms, @JsonKey(name: 'rc')  int? timeToReconnectP50Ms, @JsonKey(name: 'rcp95')  int? timeToReconnectP95Ms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2ConnectionStats() when $default != null:
return $default(_that.attempts,_that.successes,_that.failuresByReason,_that.drops,_that.silentReconnects,_that.visibleReconnects,_that.timeToConnectP50Ms,_that.timeToConnectP95Ms,_that.timeToReconnectP50Ms,_that.timeToReconnectP95Ms);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'at')  int attempts, @JsonKey(name: 'su')  int successes, @JsonKey(name: 'fr')  Map<String, int> failuresByReason, @JsonKey(name: 'dr')  int drops, @JsonKey(name: 'sr')  int silentReconnects, @JsonKey(name: 'vr')  int visibleReconnects, @JsonKey(name: 'tc')  int? timeToConnectP50Ms, @JsonKey(name: 'tcp95')  int? timeToConnectP95Ms, @JsonKey(name: 'rc')  int? timeToReconnectP50Ms, @JsonKey(name: 'rcp95')  int? timeToReconnectP95Ms)  $default,) {final _that = this;
switch (_that) {
case _Obd2ConnectionStats():
return $default(_that.attempts,_that.successes,_that.failuresByReason,_that.drops,_that.silentReconnects,_that.visibleReconnects,_that.timeToConnectP50Ms,_that.timeToConnectP95Ms,_that.timeToReconnectP50Ms,_that.timeToReconnectP95Ms);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'at')  int attempts, @JsonKey(name: 'su')  int successes, @JsonKey(name: 'fr')  Map<String, int> failuresByReason, @JsonKey(name: 'dr')  int drops, @JsonKey(name: 'sr')  int silentReconnects, @JsonKey(name: 'vr')  int visibleReconnects, @JsonKey(name: 'tc')  int? timeToConnectP50Ms, @JsonKey(name: 'tcp95')  int? timeToConnectP95Ms, @JsonKey(name: 'rc')  int? timeToReconnectP50Ms, @JsonKey(name: 'rcp95')  int? timeToReconnectP95Ms)?  $default,) {final _that = this;
switch (_that) {
case _Obd2ConnectionStats() when $default != null:
return $default(_that.attempts,_that.successes,_that.failuresByReason,_that.drops,_that.silentReconnects,_that.visibleReconnects,_that.timeToConnectP50Ms,_that.timeToConnectP95Ms,_that.timeToReconnectP50Ms,_that.timeToReconnectP95Ms);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2ConnectionStats implements Obd2ConnectionStats {
  const _Obd2ConnectionStats({@JsonKey(name: 'at') this.attempts = 0, @JsonKey(name: 'su') this.successes = 0, @JsonKey(name: 'fr') final  Map<String, int> failuresByReason = const <String, int>{}, @JsonKey(name: 'dr') this.drops = 0, @JsonKey(name: 'sr') this.silentReconnects = 0, @JsonKey(name: 'vr') this.visibleReconnects = 0, @JsonKey(name: 'tc') this.timeToConnectP50Ms, @JsonKey(name: 'tcp95') this.timeToConnectP95Ms, @JsonKey(name: 'rc') this.timeToReconnectP50Ms, @JsonKey(name: 'rcp95') this.timeToReconnectP95Ms}): _failuresByReason = failuresByReason;
  factory _Obd2ConnectionStats.fromJson(Map<String, dynamic> json) => _$Obd2ConnectionStatsFromJson(json);

/// Total connection attempts (cold + reconnect).
@override@JsonKey(name: 'at') final  int attempts;
/// Attempts that established a working link.
@override@JsonKey(name: 'su') final  int successes;
/// Map from a failure reason tag to its count (e.g.
/// `{'gattTimeout': 2, 'noElm': 1}`). Bounded by the small set of
/// known reasons.
 final  Map<String, int> _failuresByReason;
/// Map from a failure reason tag to its count (e.g.
/// `{'gattTimeout': 2, 'noElm': 1}`). Bounded by the small set of
/// known reasons.
@override@JsonKey(name: 'fr') Map<String, int> get failuresByReason {
  if (_failuresByReason is EqualUnmodifiableMapView) return _failuresByReason;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_failuresByReason);
}

/// Detected mid-session link drops.
@override@JsonKey(name: 'dr') final  int drops;
/// Reconnects that recovered without the user seeing a disconnect.
@override@JsonKey(name: 'sr') final  int silentReconnects;
/// Reconnects that surfaced a visible disconnect first.
@override@JsonKey(name: 'vr') final  int visibleReconnects;
/// Time-to-connect reservoir percentiles (ms) for cold connects.
@override@JsonKey(name: 'tc') final  int? timeToConnectP50Ms;
@override@JsonKey(name: 'tcp95') final  int? timeToConnectP95Ms;
/// Time-to-reconnect reservoir percentiles (ms).
@override@JsonKey(name: 'rc') final  int? timeToReconnectP50Ms;
@override@JsonKey(name: 'rcp95') final  int? timeToReconnectP95Ms;

/// Create a copy of Obd2ConnectionStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2ConnectionStatsCopyWith<_Obd2ConnectionStats> get copyWith => __$Obd2ConnectionStatsCopyWithImpl<_Obd2ConnectionStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2ConnectionStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2ConnectionStats&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.successes, successes) || other.successes == successes)&&const DeepCollectionEquality().equals(other._failuresByReason, _failuresByReason)&&(identical(other.drops, drops) || other.drops == drops)&&(identical(other.silentReconnects, silentReconnects) || other.silentReconnects == silentReconnects)&&(identical(other.visibleReconnects, visibleReconnects) || other.visibleReconnects == visibleReconnects)&&(identical(other.timeToConnectP50Ms, timeToConnectP50Ms) || other.timeToConnectP50Ms == timeToConnectP50Ms)&&(identical(other.timeToConnectP95Ms, timeToConnectP95Ms) || other.timeToConnectP95Ms == timeToConnectP95Ms)&&(identical(other.timeToReconnectP50Ms, timeToReconnectP50Ms) || other.timeToReconnectP50Ms == timeToReconnectP50Ms)&&(identical(other.timeToReconnectP95Ms, timeToReconnectP95Ms) || other.timeToReconnectP95Ms == timeToReconnectP95Ms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attempts,successes,const DeepCollectionEquality().hash(_failuresByReason),drops,silentReconnects,visibleReconnects,timeToConnectP50Ms,timeToConnectP95Ms,timeToReconnectP50Ms,timeToReconnectP95Ms);

@override
String toString() {
  return 'Obd2ConnectionStats(attempts: $attempts, successes: $successes, failuresByReason: $failuresByReason, drops: $drops, silentReconnects: $silentReconnects, visibleReconnects: $visibleReconnects, timeToConnectP50Ms: $timeToConnectP50Ms, timeToConnectP95Ms: $timeToConnectP95Ms, timeToReconnectP50Ms: $timeToReconnectP50Ms, timeToReconnectP95Ms: $timeToReconnectP95Ms)';
}


}

/// @nodoc
abstract mixin class _$Obd2ConnectionStatsCopyWith<$Res> implements $Obd2ConnectionStatsCopyWith<$Res> {
  factory _$Obd2ConnectionStatsCopyWith(_Obd2ConnectionStats value, $Res Function(_Obd2ConnectionStats) _then) = __$Obd2ConnectionStatsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'at') int attempts,@JsonKey(name: 'su') int successes,@JsonKey(name: 'fr') Map<String, int> failuresByReason,@JsonKey(name: 'dr') int drops,@JsonKey(name: 'sr') int silentReconnects,@JsonKey(name: 'vr') int visibleReconnects,@JsonKey(name: 'tc') int? timeToConnectP50Ms,@JsonKey(name: 'tcp95') int? timeToConnectP95Ms,@JsonKey(name: 'rc') int? timeToReconnectP50Ms,@JsonKey(name: 'rcp95') int? timeToReconnectP95Ms
});




}
/// @nodoc
class __$Obd2ConnectionStatsCopyWithImpl<$Res>
    implements _$Obd2ConnectionStatsCopyWith<$Res> {
  __$Obd2ConnectionStatsCopyWithImpl(this._self, this._then);

  final _Obd2ConnectionStats _self;
  final $Res Function(_Obd2ConnectionStats) _then;

/// Create a copy of Obd2ConnectionStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attempts = null,Object? successes = null,Object? failuresByReason = null,Object? drops = null,Object? silentReconnects = null,Object? visibleReconnects = null,Object? timeToConnectP50Ms = freezed,Object? timeToConnectP95Ms = freezed,Object? timeToReconnectP50Ms = freezed,Object? timeToReconnectP95Ms = freezed,}) {
  return _then(_Obd2ConnectionStats(
attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,successes: null == successes ? _self.successes : successes // ignore: cast_nullable_to_non_nullable
as int,failuresByReason: null == failuresByReason ? _self._failuresByReason : failuresByReason // ignore: cast_nullable_to_non_nullable
as Map<String, int>,drops: null == drops ? _self.drops : drops // ignore: cast_nullable_to_non_nullable
as int,silentReconnects: null == silentReconnects ? _self.silentReconnects : silentReconnects // ignore: cast_nullable_to_non_nullable
as int,visibleReconnects: null == visibleReconnects ? _self.visibleReconnects : visibleReconnects // ignore: cast_nullable_to_non_nullable
as int,timeToConnectP50Ms: freezed == timeToConnectP50Ms ? _self.timeToConnectP50Ms : timeToConnectP50Ms // ignore: cast_nullable_to_non_nullable
as int?,timeToConnectP95Ms: freezed == timeToConnectP95Ms ? _self.timeToConnectP95Ms : timeToConnectP95Ms // ignore: cast_nullable_to_non_nullable
as int?,timeToReconnectP50Ms: freezed == timeToReconnectP50Ms ? _self.timeToReconnectP50Ms : timeToReconnectP50Ms // ignore: cast_nullable_to_non_nullable
as int?,timeToReconnectP95Ms: freezed == timeToReconnectP95Ms ? _self.timeToReconnectP95Ms : timeToReconnectP95Ms // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Obd2SchedulerStats {

/// Achieved tick-rate (Hz), the effective poll loop frequency.
@JsonKey(name: 'tr') double get tickRateHz;/// Ticks skipped because the previous read had not completed
/// (back-pressure) — the scheduler's `_inFlight != null` early return.
@JsonKey(name: 'bp') int get backpressureSkips;/// Governor demotions currently in force — count of commands the
/// bandwidth governor has demoted to claw back budget for the dynamics
/// tier on a slow link.
@JsonKey(name: 'dm') int get demotions;/// Total scheduler ticks observed (fired commands + backpressure
/// skips). The denominator that makes [backpressureSkips] a rate.
@JsonKey(name: 'tk') int get ticks;/// Achieved total reads/second across all PIDs over the governor's
/// rolling window (`GovernorState.achievedReadsPerSecond`).
@JsonKey(name: 'rps') double get achievedReadsPerSecond;/// Effective reads/s the slowest dynamics-tier PID is achieving — the
/// metric the governor floors. May be very large /
/// [double.infinity]-derived before two dynamics reads land; the tee
/// clamps the infinity sentinel to 0 so the JSON stays finite.
@JsonKey(name: 'dhz') double get dynamicsEffectiveHz;/// PIDs currently in the #2379 backed-off state (≥3 consecutive
/// failures) — the broadly-unresponsive-adapter indicator.
@JsonKey(name: 'bof') int get backedOffCount;/// Starvation indicator: true when the dynamics tier dropped below its
/// floor (`dynamicsEffectiveHz` measured and < the governor floor) —
/// RPM / speed are not keeping up despite the floor protection.
@JsonKey(name: 'st') bool get starved;
/// Create a copy of Obd2SchedulerStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2SchedulerStatsCopyWith<Obd2SchedulerStats> get copyWith => _$Obd2SchedulerStatsCopyWithImpl<Obd2SchedulerStats>(this as Obd2SchedulerStats, _$identity);

  /// Serializes this Obd2SchedulerStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2SchedulerStats&&(identical(other.tickRateHz, tickRateHz) || other.tickRateHz == tickRateHz)&&(identical(other.backpressureSkips, backpressureSkips) || other.backpressureSkips == backpressureSkips)&&(identical(other.demotions, demotions) || other.demotions == demotions)&&(identical(other.ticks, ticks) || other.ticks == ticks)&&(identical(other.achievedReadsPerSecond, achievedReadsPerSecond) || other.achievedReadsPerSecond == achievedReadsPerSecond)&&(identical(other.dynamicsEffectiveHz, dynamicsEffectiveHz) || other.dynamicsEffectiveHz == dynamicsEffectiveHz)&&(identical(other.backedOffCount, backedOffCount) || other.backedOffCount == backedOffCount)&&(identical(other.starved, starved) || other.starved == starved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tickRateHz,backpressureSkips,demotions,ticks,achievedReadsPerSecond,dynamicsEffectiveHz,backedOffCount,starved);

@override
String toString() {
  return 'Obd2SchedulerStats(tickRateHz: $tickRateHz, backpressureSkips: $backpressureSkips, demotions: $demotions, ticks: $ticks, achievedReadsPerSecond: $achievedReadsPerSecond, dynamicsEffectiveHz: $dynamicsEffectiveHz, backedOffCount: $backedOffCount, starved: $starved)';
}


}

/// @nodoc
abstract mixin class $Obd2SchedulerStatsCopyWith<$Res>  {
  factory $Obd2SchedulerStatsCopyWith(Obd2SchedulerStats value, $Res Function(Obd2SchedulerStats) _then) = _$Obd2SchedulerStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'tr') double tickRateHz,@JsonKey(name: 'bp') int backpressureSkips,@JsonKey(name: 'dm') int demotions,@JsonKey(name: 'tk') int ticks,@JsonKey(name: 'rps') double achievedReadsPerSecond,@JsonKey(name: 'dhz') double dynamicsEffectiveHz,@JsonKey(name: 'bof') int backedOffCount,@JsonKey(name: 'st') bool starved
});




}
/// @nodoc
class _$Obd2SchedulerStatsCopyWithImpl<$Res>
    implements $Obd2SchedulerStatsCopyWith<$Res> {
  _$Obd2SchedulerStatsCopyWithImpl(this._self, this._then);

  final Obd2SchedulerStats _self;
  final $Res Function(Obd2SchedulerStats) _then;

/// Create a copy of Obd2SchedulerStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tickRateHz = null,Object? backpressureSkips = null,Object? demotions = null,Object? ticks = null,Object? achievedReadsPerSecond = null,Object? dynamicsEffectiveHz = null,Object? backedOffCount = null,Object? starved = null,}) {
  return _then(_self.copyWith(
tickRateHz: null == tickRateHz ? _self.tickRateHz : tickRateHz // ignore: cast_nullable_to_non_nullable
as double,backpressureSkips: null == backpressureSkips ? _self.backpressureSkips : backpressureSkips // ignore: cast_nullable_to_non_nullable
as int,demotions: null == demotions ? _self.demotions : demotions // ignore: cast_nullable_to_non_nullable
as int,ticks: null == ticks ? _self.ticks : ticks // ignore: cast_nullable_to_non_nullable
as int,achievedReadsPerSecond: null == achievedReadsPerSecond ? _self.achievedReadsPerSecond : achievedReadsPerSecond // ignore: cast_nullable_to_non_nullable
as double,dynamicsEffectiveHz: null == dynamicsEffectiveHz ? _self.dynamicsEffectiveHz : dynamicsEffectiveHz // ignore: cast_nullable_to_non_nullable
as double,backedOffCount: null == backedOffCount ? _self.backedOffCount : backedOffCount // ignore: cast_nullable_to_non_nullable
as int,starved: null == starved ? _self.starved : starved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2SchedulerStats].
extension Obd2SchedulerStatsPatterns on Obd2SchedulerStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2SchedulerStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2SchedulerStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2SchedulerStats value)  $default,){
final _that = this;
switch (_that) {
case _Obd2SchedulerStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2SchedulerStats value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2SchedulerStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'tr')  double tickRateHz, @JsonKey(name: 'bp')  int backpressureSkips, @JsonKey(name: 'dm')  int demotions, @JsonKey(name: 'tk')  int ticks, @JsonKey(name: 'rps')  double achievedReadsPerSecond, @JsonKey(name: 'dhz')  double dynamicsEffectiveHz, @JsonKey(name: 'bof')  int backedOffCount, @JsonKey(name: 'st')  bool starved)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2SchedulerStats() when $default != null:
return $default(_that.tickRateHz,_that.backpressureSkips,_that.demotions,_that.ticks,_that.achievedReadsPerSecond,_that.dynamicsEffectiveHz,_that.backedOffCount,_that.starved);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'tr')  double tickRateHz, @JsonKey(name: 'bp')  int backpressureSkips, @JsonKey(name: 'dm')  int demotions, @JsonKey(name: 'tk')  int ticks, @JsonKey(name: 'rps')  double achievedReadsPerSecond, @JsonKey(name: 'dhz')  double dynamicsEffectiveHz, @JsonKey(name: 'bof')  int backedOffCount, @JsonKey(name: 'st')  bool starved)  $default,) {final _that = this;
switch (_that) {
case _Obd2SchedulerStats():
return $default(_that.tickRateHz,_that.backpressureSkips,_that.demotions,_that.ticks,_that.achievedReadsPerSecond,_that.dynamicsEffectiveHz,_that.backedOffCount,_that.starved);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'tr')  double tickRateHz, @JsonKey(name: 'bp')  int backpressureSkips, @JsonKey(name: 'dm')  int demotions, @JsonKey(name: 'tk')  int ticks, @JsonKey(name: 'rps')  double achievedReadsPerSecond, @JsonKey(name: 'dhz')  double dynamicsEffectiveHz, @JsonKey(name: 'bof')  int backedOffCount, @JsonKey(name: 'st')  bool starved)?  $default,) {final _that = this;
switch (_that) {
case _Obd2SchedulerStats() when $default != null:
return $default(_that.tickRateHz,_that.backpressureSkips,_that.demotions,_that.ticks,_that.achievedReadsPerSecond,_that.dynamicsEffectiveHz,_that.backedOffCount,_that.starved);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2SchedulerStats implements Obd2SchedulerStats {
  const _Obd2SchedulerStats({@JsonKey(name: 'tr') this.tickRateHz = 0.0, @JsonKey(name: 'bp') this.backpressureSkips = 0, @JsonKey(name: 'dm') this.demotions = 0, @JsonKey(name: 'tk') this.ticks = 0, @JsonKey(name: 'rps') this.achievedReadsPerSecond = 0.0, @JsonKey(name: 'dhz') this.dynamicsEffectiveHz = 0.0, @JsonKey(name: 'bof') this.backedOffCount = 0, @JsonKey(name: 'st') this.starved = false});
  factory _Obd2SchedulerStats.fromJson(Map<String, dynamic> json) => _$Obd2SchedulerStatsFromJson(json);

/// Achieved tick-rate (Hz), the effective poll loop frequency.
@override@JsonKey(name: 'tr') final  double tickRateHz;
/// Ticks skipped because the previous read had not completed
/// (back-pressure) — the scheduler's `_inFlight != null` early return.
@override@JsonKey(name: 'bp') final  int backpressureSkips;
/// Governor demotions currently in force — count of commands the
/// bandwidth governor has demoted to claw back budget for the dynamics
/// tier on a slow link.
@override@JsonKey(name: 'dm') final  int demotions;
/// Total scheduler ticks observed (fired commands + backpressure
/// skips). The denominator that makes [backpressureSkips] a rate.
@override@JsonKey(name: 'tk') final  int ticks;
/// Achieved total reads/second across all PIDs over the governor's
/// rolling window (`GovernorState.achievedReadsPerSecond`).
@override@JsonKey(name: 'rps') final  double achievedReadsPerSecond;
/// Effective reads/s the slowest dynamics-tier PID is achieving — the
/// metric the governor floors. May be very large /
/// [double.infinity]-derived before two dynamics reads land; the tee
/// clamps the infinity sentinel to 0 so the JSON stays finite.
@override@JsonKey(name: 'dhz') final  double dynamicsEffectiveHz;
/// PIDs currently in the #2379 backed-off state (≥3 consecutive
/// failures) — the broadly-unresponsive-adapter indicator.
@override@JsonKey(name: 'bof') final  int backedOffCount;
/// Starvation indicator: true when the dynamics tier dropped below its
/// floor (`dynamicsEffectiveHz` measured and < the governor floor) —
/// RPM / speed are not keeping up despite the floor protection.
@override@JsonKey(name: 'st') final  bool starved;

/// Create a copy of Obd2SchedulerStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2SchedulerStatsCopyWith<_Obd2SchedulerStats> get copyWith => __$Obd2SchedulerStatsCopyWithImpl<_Obd2SchedulerStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2SchedulerStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2SchedulerStats&&(identical(other.tickRateHz, tickRateHz) || other.tickRateHz == tickRateHz)&&(identical(other.backpressureSkips, backpressureSkips) || other.backpressureSkips == backpressureSkips)&&(identical(other.demotions, demotions) || other.demotions == demotions)&&(identical(other.ticks, ticks) || other.ticks == ticks)&&(identical(other.achievedReadsPerSecond, achievedReadsPerSecond) || other.achievedReadsPerSecond == achievedReadsPerSecond)&&(identical(other.dynamicsEffectiveHz, dynamicsEffectiveHz) || other.dynamicsEffectiveHz == dynamicsEffectiveHz)&&(identical(other.backedOffCount, backedOffCount) || other.backedOffCount == backedOffCount)&&(identical(other.starved, starved) || other.starved == starved));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tickRateHz,backpressureSkips,demotions,ticks,achievedReadsPerSecond,dynamicsEffectiveHz,backedOffCount,starved);

@override
String toString() {
  return 'Obd2SchedulerStats(tickRateHz: $tickRateHz, backpressureSkips: $backpressureSkips, demotions: $demotions, ticks: $ticks, achievedReadsPerSecond: $achievedReadsPerSecond, dynamicsEffectiveHz: $dynamicsEffectiveHz, backedOffCount: $backedOffCount, starved: $starved)';
}


}

/// @nodoc
abstract mixin class _$Obd2SchedulerStatsCopyWith<$Res> implements $Obd2SchedulerStatsCopyWith<$Res> {
  factory _$Obd2SchedulerStatsCopyWith(_Obd2SchedulerStats value, $Res Function(_Obd2SchedulerStats) _then) = __$Obd2SchedulerStatsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'tr') double tickRateHz,@JsonKey(name: 'bp') int backpressureSkips,@JsonKey(name: 'dm') int demotions,@JsonKey(name: 'tk') int ticks,@JsonKey(name: 'rps') double achievedReadsPerSecond,@JsonKey(name: 'dhz') double dynamicsEffectiveHz,@JsonKey(name: 'bof') int backedOffCount,@JsonKey(name: 'st') bool starved
});




}
/// @nodoc
class __$Obd2SchedulerStatsCopyWithImpl<$Res>
    implements _$Obd2SchedulerStatsCopyWith<$Res> {
  __$Obd2SchedulerStatsCopyWithImpl(this._self, this._then);

  final _Obd2SchedulerStats _self;
  final $Res Function(_Obd2SchedulerStats) _then;

/// Create a copy of Obd2SchedulerStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tickRateHz = null,Object? backpressureSkips = null,Object? demotions = null,Object? ticks = null,Object? achievedReadsPerSecond = null,Object? dynamicsEffectiveHz = null,Object? backedOffCount = null,Object? starved = null,}) {
  return _then(_Obd2SchedulerStats(
tickRateHz: null == tickRateHz ? _self.tickRateHz : tickRateHz // ignore: cast_nullable_to_non_nullable
as double,backpressureSkips: null == backpressureSkips ? _self.backpressureSkips : backpressureSkips // ignore: cast_nullable_to_non_nullable
as int,demotions: null == demotions ? _self.demotions : demotions // ignore: cast_nullable_to_non_nullable
as int,ticks: null == ticks ? _self.ticks : ticks // ignore: cast_nullable_to_non_nullable
as int,achievedReadsPerSecond: null == achievedReadsPerSecond ? _self.achievedReadsPerSecond : achievedReadsPerSecond // ignore: cast_nullable_to_non_nullable
as double,dynamicsEffectiveHz: null == dynamicsEffectiveHz ? _self.dynamicsEffectiveHz : dynamicsEffectiveHz // ignore: cast_nullable_to_non_nullable
as double,backedOffCount: null == backedOffCount ? _self.backedOffCount : backedOffCount // ignore: cast_nullable_to_non_nullable
as int,starved: null == starved ? _self.starved : starved // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Obd2FuelDowngradeStats {

/// Total fuel-rate samples seen this session.
@JsonKey(name: 't') int get totalSamples;/// Samples that tripped a sanity flag (suspicious-low / 5E-vs-MAF
/// divergent) — the numerator of the suspicion ratio.
@JsonKey(name: 's') int get suspiciousSamples;
/// Create a copy of Obd2FuelDowngradeStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2FuelDowngradeStatsCopyWith<Obd2FuelDowngradeStats> get copyWith => _$Obd2FuelDowngradeStatsCopyWithImpl<Obd2FuelDowngradeStats>(this as Obd2FuelDowngradeStats, _$identity);

  /// Serializes this Obd2FuelDowngradeStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2FuelDowngradeStats&&(identical(other.totalSamples, totalSamples) || other.totalSamples == totalSamples)&&(identical(other.suspiciousSamples, suspiciousSamples) || other.suspiciousSamples == suspiciousSamples));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalSamples,suspiciousSamples);

@override
String toString() {
  return 'Obd2FuelDowngradeStats(totalSamples: $totalSamples, suspiciousSamples: $suspiciousSamples)';
}


}

/// @nodoc
abstract mixin class $Obd2FuelDowngradeStatsCopyWith<$Res>  {
  factory $Obd2FuelDowngradeStatsCopyWith(Obd2FuelDowngradeStats value, $Res Function(Obd2FuelDowngradeStats) _then) = _$Obd2FuelDowngradeStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 't') int totalSamples,@JsonKey(name: 's') int suspiciousSamples
});




}
/// @nodoc
class _$Obd2FuelDowngradeStatsCopyWithImpl<$Res>
    implements $Obd2FuelDowngradeStatsCopyWith<$Res> {
  _$Obd2FuelDowngradeStatsCopyWithImpl(this._self, this._then);

  final Obd2FuelDowngradeStats _self;
  final $Res Function(Obd2FuelDowngradeStats) _then;

/// Create a copy of Obd2FuelDowngradeStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalSamples = null,Object? suspiciousSamples = null,}) {
  return _then(_self.copyWith(
totalSamples: null == totalSamples ? _self.totalSamples : totalSamples // ignore: cast_nullable_to_non_nullable
as int,suspiciousSamples: null == suspiciousSamples ? _self.suspiciousSamples : suspiciousSamples // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2FuelDowngradeStats].
extension Obd2FuelDowngradeStatsPatterns on Obd2FuelDowngradeStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2FuelDowngradeStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2FuelDowngradeStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2FuelDowngradeStats value)  $default,){
final _that = this;
switch (_that) {
case _Obd2FuelDowngradeStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2FuelDowngradeStats value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2FuelDowngradeStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int totalSamples, @JsonKey(name: 's')  int suspiciousSamples)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2FuelDowngradeStats() when $default != null:
return $default(_that.totalSamples,_that.suspiciousSamples);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 't')  int totalSamples, @JsonKey(name: 's')  int suspiciousSamples)  $default,) {final _that = this;
switch (_that) {
case _Obd2FuelDowngradeStats():
return $default(_that.totalSamples,_that.suspiciousSamples);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 't')  int totalSamples, @JsonKey(name: 's')  int suspiciousSamples)?  $default,) {final _that = this;
switch (_that) {
case _Obd2FuelDowngradeStats() when $default != null:
return $default(_that.totalSamples,_that.suspiciousSamples);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2FuelDowngradeStats extends Obd2FuelDowngradeStats {
  const _Obd2FuelDowngradeStats({@JsonKey(name: 't') this.totalSamples = 0, @JsonKey(name: 's') this.suspiciousSamples = 0}): super._();
  factory _Obd2FuelDowngradeStats.fromJson(Map<String, dynamic> json) => _$Obd2FuelDowngradeStatsFromJson(json);

/// Total fuel-rate samples seen this session.
@override@JsonKey(name: 't') final  int totalSamples;
/// Samples that tripped a sanity flag (suspicious-low / 5E-vs-MAF
/// divergent) — the numerator of the suspicion ratio.
@override@JsonKey(name: 's') final  int suspiciousSamples;

/// Create a copy of Obd2FuelDowngradeStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2FuelDowngradeStatsCopyWith<_Obd2FuelDowngradeStats> get copyWith => __$Obd2FuelDowngradeStatsCopyWithImpl<_Obd2FuelDowngradeStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2FuelDowngradeStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2FuelDowngradeStats&&(identical(other.totalSamples, totalSamples) || other.totalSamples == totalSamples)&&(identical(other.suspiciousSamples, suspiciousSamples) || other.suspiciousSamples == suspiciousSamples));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalSamples,suspiciousSamples);

@override
String toString() {
  return 'Obd2FuelDowngradeStats(totalSamples: $totalSamples, suspiciousSamples: $suspiciousSamples)';
}


}

/// @nodoc
abstract mixin class _$Obd2FuelDowngradeStatsCopyWith<$Res> implements $Obd2FuelDowngradeStatsCopyWith<$Res> {
  factory _$Obd2FuelDowngradeStatsCopyWith(_Obd2FuelDowngradeStats value, $Res Function(_Obd2FuelDowngradeStats) _then) = __$Obd2FuelDowngradeStatsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 't') int totalSamples,@JsonKey(name: 's') int suspiciousSamples
});




}
/// @nodoc
class __$Obd2FuelDowngradeStatsCopyWithImpl<$Res>
    implements _$Obd2FuelDowngradeStatsCopyWith<$Res> {
  __$Obd2FuelDowngradeStatsCopyWithImpl(this._self, this._then);

  final _Obd2FuelDowngradeStats _self;
  final $Res Function(_Obd2FuelDowngradeStats) _then;

/// Create a copy of Obd2FuelDowngradeStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalSamples = null,Object? suspiciousSamples = null,}) {
  return _then(_Obd2FuelDowngradeStats(
totalSamples: null == totalSamples ? _self.totalSamples : totalSamples // ignore: cast_nullable_to_non_nullable
as int,suspiciousSamples: null == suspiciousSamples ? _self.suspiciousSamples : suspiciousSamples // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Obd2CompletenessStats {

/// Overall `Σ ok / Σ(targetHz × activeSeconds)` as a 0–100 percentage.
/// 0 when nothing was expected (no active seconds / no targets).
@JsonKey(name: 'o') double get overallPercent;/// Per-tier completeness percentage keyed by tier name
/// (`'dynamics'`/`'mixture'`/`'slowCorrection'`/`'thermalContext'`).
@JsonKey(name: 'pt') Map<String, double> get perTierPercent;/// Fraction (0–1) of the session the scheduler was actively polling —
/// `min(1, totalAchievedReads / totalExpectedReads)`, clamped. A proxy
/// for "was the link delivering" vs idle/stalled.
@JsonKey(name: 'dc') double get activeDutyCycle;/// True when an emit-index gap was detected — a tier whose attainment
/// fell below [emitGapThreshold], i.e. the scheduler skipped a
/// meaningful share of that tier's expected reads.
@JsonKey(name: 'eg') bool get emitGapDetected;
/// Create a copy of Obd2CompletenessStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2CompletenessStatsCopyWith<Obd2CompletenessStats> get copyWith => _$Obd2CompletenessStatsCopyWithImpl<Obd2CompletenessStats>(this as Obd2CompletenessStats, _$identity);

  /// Serializes this Obd2CompletenessStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2CompletenessStats&&(identical(other.overallPercent, overallPercent) || other.overallPercent == overallPercent)&&const DeepCollectionEquality().equals(other.perTierPercent, perTierPercent)&&(identical(other.activeDutyCycle, activeDutyCycle) || other.activeDutyCycle == activeDutyCycle)&&(identical(other.emitGapDetected, emitGapDetected) || other.emitGapDetected == emitGapDetected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallPercent,const DeepCollectionEquality().hash(perTierPercent),activeDutyCycle,emitGapDetected);

@override
String toString() {
  return 'Obd2CompletenessStats(overallPercent: $overallPercent, perTierPercent: $perTierPercent, activeDutyCycle: $activeDutyCycle, emitGapDetected: $emitGapDetected)';
}


}

/// @nodoc
abstract mixin class $Obd2CompletenessStatsCopyWith<$Res>  {
  factory $Obd2CompletenessStatsCopyWith(Obd2CompletenessStats value, $Res Function(Obd2CompletenessStats) _then) = _$Obd2CompletenessStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'o') double overallPercent,@JsonKey(name: 'pt') Map<String, double> perTierPercent,@JsonKey(name: 'dc') double activeDutyCycle,@JsonKey(name: 'eg') bool emitGapDetected
});




}
/// @nodoc
class _$Obd2CompletenessStatsCopyWithImpl<$Res>
    implements $Obd2CompletenessStatsCopyWith<$Res> {
  _$Obd2CompletenessStatsCopyWithImpl(this._self, this._then);

  final Obd2CompletenessStats _self;
  final $Res Function(Obd2CompletenessStats) _then;

/// Create a copy of Obd2CompletenessStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overallPercent = null,Object? perTierPercent = null,Object? activeDutyCycle = null,Object? emitGapDetected = null,}) {
  return _then(_self.copyWith(
overallPercent: null == overallPercent ? _self.overallPercent : overallPercent // ignore: cast_nullable_to_non_nullable
as double,perTierPercent: null == perTierPercent ? _self.perTierPercent : perTierPercent // ignore: cast_nullable_to_non_nullable
as Map<String, double>,activeDutyCycle: null == activeDutyCycle ? _self.activeDutyCycle : activeDutyCycle // ignore: cast_nullable_to_non_nullable
as double,emitGapDetected: null == emitGapDetected ? _self.emitGapDetected : emitGapDetected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2CompletenessStats].
extension Obd2CompletenessStatsPatterns on Obd2CompletenessStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2CompletenessStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2CompletenessStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2CompletenessStats value)  $default,){
final _that = this;
switch (_that) {
case _Obd2CompletenessStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2CompletenessStats value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2CompletenessStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'o')  double overallPercent, @JsonKey(name: 'pt')  Map<String, double> perTierPercent, @JsonKey(name: 'dc')  double activeDutyCycle, @JsonKey(name: 'eg')  bool emitGapDetected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2CompletenessStats() when $default != null:
return $default(_that.overallPercent,_that.perTierPercent,_that.activeDutyCycle,_that.emitGapDetected);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'o')  double overallPercent, @JsonKey(name: 'pt')  Map<String, double> perTierPercent, @JsonKey(name: 'dc')  double activeDutyCycle, @JsonKey(name: 'eg')  bool emitGapDetected)  $default,) {final _that = this;
switch (_that) {
case _Obd2CompletenessStats():
return $default(_that.overallPercent,_that.perTierPercent,_that.activeDutyCycle,_that.emitGapDetected);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'o')  double overallPercent, @JsonKey(name: 'pt')  Map<String, double> perTierPercent, @JsonKey(name: 'dc')  double activeDutyCycle, @JsonKey(name: 'eg')  bool emitGapDetected)?  $default,) {final _that = this;
switch (_that) {
case _Obd2CompletenessStats() when $default != null:
return $default(_that.overallPercent,_that.perTierPercent,_that.activeDutyCycle,_that.emitGapDetected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2CompletenessStats implements Obd2CompletenessStats {
  const _Obd2CompletenessStats({@JsonKey(name: 'o') this.overallPercent = 0.0, @JsonKey(name: 'pt') final  Map<String, double> perTierPercent = const <String, double>{}, @JsonKey(name: 'dc') this.activeDutyCycle = 0.0, @JsonKey(name: 'eg') this.emitGapDetected = false}): _perTierPercent = perTierPercent;
  factory _Obd2CompletenessStats.fromJson(Map<String, dynamic> json) => _$Obd2CompletenessStatsFromJson(json);

/// Overall `Σ ok / Σ(targetHz × activeSeconds)` as a 0–100 percentage.
/// 0 when nothing was expected (no active seconds / no targets).
@override@JsonKey(name: 'o') final  double overallPercent;
/// Per-tier completeness percentage keyed by tier name
/// (`'dynamics'`/`'mixture'`/`'slowCorrection'`/`'thermalContext'`).
 final  Map<String, double> _perTierPercent;
/// Per-tier completeness percentage keyed by tier name
/// (`'dynamics'`/`'mixture'`/`'slowCorrection'`/`'thermalContext'`).
@override@JsonKey(name: 'pt') Map<String, double> get perTierPercent {
  if (_perTierPercent is EqualUnmodifiableMapView) return _perTierPercent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_perTierPercent);
}

/// Fraction (0–1) of the session the scheduler was actively polling —
/// `min(1, totalAchievedReads / totalExpectedReads)`, clamped. A proxy
/// for "was the link delivering" vs idle/stalled.
@override@JsonKey(name: 'dc') final  double activeDutyCycle;
/// True when an emit-index gap was detected — a tier whose attainment
/// fell below [emitGapThreshold], i.e. the scheduler skipped a
/// meaningful share of that tier's expected reads.
@override@JsonKey(name: 'eg') final  bool emitGapDetected;

/// Create a copy of Obd2CompletenessStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2CompletenessStatsCopyWith<_Obd2CompletenessStats> get copyWith => __$Obd2CompletenessStatsCopyWithImpl<_Obd2CompletenessStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2CompletenessStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2CompletenessStats&&(identical(other.overallPercent, overallPercent) || other.overallPercent == overallPercent)&&const DeepCollectionEquality().equals(other._perTierPercent, _perTierPercent)&&(identical(other.activeDutyCycle, activeDutyCycle) || other.activeDutyCycle == activeDutyCycle)&&(identical(other.emitGapDetected, emitGapDetected) || other.emitGapDetected == emitGapDetected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overallPercent,const DeepCollectionEquality().hash(_perTierPercent),activeDutyCycle,emitGapDetected);

@override
String toString() {
  return 'Obd2CompletenessStats(overallPercent: $overallPercent, perTierPercent: $perTierPercent, activeDutyCycle: $activeDutyCycle, emitGapDetected: $emitGapDetected)';
}


}

/// @nodoc
abstract mixin class _$Obd2CompletenessStatsCopyWith<$Res> implements $Obd2CompletenessStatsCopyWith<$Res> {
  factory _$Obd2CompletenessStatsCopyWith(_Obd2CompletenessStats value, $Res Function(_Obd2CompletenessStats) _then) = __$Obd2CompletenessStatsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'o') double overallPercent,@JsonKey(name: 'pt') Map<String, double> perTierPercent,@JsonKey(name: 'dc') double activeDutyCycle,@JsonKey(name: 'eg') bool emitGapDetected
});




}
/// @nodoc
class __$Obd2CompletenessStatsCopyWithImpl<$Res>
    implements _$Obd2CompletenessStatsCopyWith<$Res> {
  __$Obd2CompletenessStatsCopyWithImpl(this._self, this._then);

  final _Obd2CompletenessStats _self;
  final $Res Function(_Obd2CompletenessStats) _then;

/// Create a copy of Obd2CompletenessStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overallPercent = null,Object? perTierPercent = null,Object? activeDutyCycle = null,Object? emitGapDetected = null,}) {
  return _then(_Obd2CompletenessStats(
overallPercent: null == overallPercent ? _self.overallPercent : overallPercent // ignore: cast_nullable_to_non_nullable
as double,perTierPercent: null == perTierPercent ? _self._perTierPercent : perTierPercent // ignore: cast_nullable_to_non_nullable
as Map<String, double>,activeDutyCycle: null == activeDutyCycle ? _self.activeDutyCycle : activeDutyCycle // ignore: cast_nullable_to_non_nullable
as double,emitGapDetected: null == emitGapDetected ? _self.emitGapDetected : emitGapDetected // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Obd2FramingStats {

/// Reads that arrived as an incomplete frame (no terminating prompt).
@JsonKey(name: 'pf') int get partialFrames;/// Reads where leftover bytes from a prior frame prefixed this one.
@JsonKey(name: 'lo') int get leftoverBytes;/// Stray bare `>` prompts read with no data.
@JsonKey(name: 'sp') int get strayPrompts;/// Reads that classified as [ResponseClass.garbage].
@JsonKey(name: 'gb') int get garbageReads;
/// Create a copy of Obd2FramingStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Obd2FramingStatsCopyWith<Obd2FramingStats> get copyWith => _$Obd2FramingStatsCopyWithImpl<Obd2FramingStats>(this as Obd2FramingStats, _$identity);

  /// Serializes this Obd2FramingStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Obd2FramingStats&&(identical(other.partialFrames, partialFrames) || other.partialFrames == partialFrames)&&(identical(other.leftoverBytes, leftoverBytes) || other.leftoverBytes == leftoverBytes)&&(identical(other.strayPrompts, strayPrompts) || other.strayPrompts == strayPrompts)&&(identical(other.garbageReads, garbageReads) || other.garbageReads == garbageReads));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,partialFrames,leftoverBytes,strayPrompts,garbageReads);

@override
String toString() {
  return 'Obd2FramingStats(partialFrames: $partialFrames, leftoverBytes: $leftoverBytes, strayPrompts: $strayPrompts, garbageReads: $garbageReads)';
}


}

/// @nodoc
abstract mixin class $Obd2FramingStatsCopyWith<$Res>  {
  factory $Obd2FramingStatsCopyWith(Obd2FramingStats value, $Res Function(Obd2FramingStats) _then) = _$Obd2FramingStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'pf') int partialFrames,@JsonKey(name: 'lo') int leftoverBytes,@JsonKey(name: 'sp') int strayPrompts,@JsonKey(name: 'gb') int garbageReads
});




}
/// @nodoc
class _$Obd2FramingStatsCopyWithImpl<$Res>
    implements $Obd2FramingStatsCopyWith<$Res> {
  _$Obd2FramingStatsCopyWithImpl(this._self, this._then);

  final Obd2FramingStats _self;
  final $Res Function(Obd2FramingStats) _then;

/// Create a copy of Obd2FramingStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? partialFrames = null,Object? leftoverBytes = null,Object? strayPrompts = null,Object? garbageReads = null,}) {
  return _then(_self.copyWith(
partialFrames: null == partialFrames ? _self.partialFrames : partialFrames // ignore: cast_nullable_to_non_nullable
as int,leftoverBytes: null == leftoverBytes ? _self.leftoverBytes : leftoverBytes // ignore: cast_nullable_to_non_nullable
as int,strayPrompts: null == strayPrompts ? _self.strayPrompts : strayPrompts // ignore: cast_nullable_to_non_nullable
as int,garbageReads: null == garbageReads ? _self.garbageReads : garbageReads // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Obd2FramingStats].
extension Obd2FramingStatsPatterns on Obd2FramingStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Obd2FramingStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Obd2FramingStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Obd2FramingStats value)  $default,){
final _that = this;
switch (_that) {
case _Obd2FramingStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Obd2FramingStats value)?  $default,){
final _that = this;
switch (_that) {
case _Obd2FramingStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'pf')  int partialFrames, @JsonKey(name: 'lo')  int leftoverBytes, @JsonKey(name: 'sp')  int strayPrompts, @JsonKey(name: 'gb')  int garbageReads)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Obd2FramingStats() when $default != null:
return $default(_that.partialFrames,_that.leftoverBytes,_that.strayPrompts,_that.garbageReads);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'pf')  int partialFrames, @JsonKey(name: 'lo')  int leftoverBytes, @JsonKey(name: 'sp')  int strayPrompts, @JsonKey(name: 'gb')  int garbageReads)  $default,) {final _that = this;
switch (_that) {
case _Obd2FramingStats():
return $default(_that.partialFrames,_that.leftoverBytes,_that.strayPrompts,_that.garbageReads);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'pf')  int partialFrames, @JsonKey(name: 'lo')  int leftoverBytes, @JsonKey(name: 'sp')  int strayPrompts, @JsonKey(name: 'gb')  int garbageReads)?  $default,) {final _that = this;
switch (_that) {
case _Obd2FramingStats() when $default != null:
return $default(_that.partialFrames,_that.leftoverBytes,_that.strayPrompts,_that.garbageReads);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Obd2FramingStats implements Obd2FramingStats {
  const _Obd2FramingStats({@JsonKey(name: 'pf') this.partialFrames = 0, @JsonKey(name: 'lo') this.leftoverBytes = 0, @JsonKey(name: 'sp') this.strayPrompts = 0, @JsonKey(name: 'gb') this.garbageReads = 0});
  factory _Obd2FramingStats.fromJson(Map<String, dynamic> json) => _$Obd2FramingStatsFromJson(json);

/// Reads that arrived as an incomplete frame (no terminating prompt).
@override@JsonKey(name: 'pf') final  int partialFrames;
/// Reads where leftover bytes from a prior frame prefixed this one.
@override@JsonKey(name: 'lo') final  int leftoverBytes;
/// Stray bare `>` prompts read with no data.
@override@JsonKey(name: 'sp') final  int strayPrompts;
/// Reads that classified as [ResponseClass.garbage].
@override@JsonKey(name: 'gb') final  int garbageReads;

/// Create a copy of Obd2FramingStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Obd2FramingStatsCopyWith<_Obd2FramingStats> get copyWith => __$Obd2FramingStatsCopyWithImpl<_Obd2FramingStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Obd2FramingStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Obd2FramingStats&&(identical(other.partialFrames, partialFrames) || other.partialFrames == partialFrames)&&(identical(other.leftoverBytes, leftoverBytes) || other.leftoverBytes == leftoverBytes)&&(identical(other.strayPrompts, strayPrompts) || other.strayPrompts == strayPrompts)&&(identical(other.garbageReads, garbageReads) || other.garbageReads == garbageReads));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,partialFrames,leftoverBytes,strayPrompts,garbageReads);

@override
String toString() {
  return 'Obd2FramingStats(partialFrames: $partialFrames, leftoverBytes: $leftoverBytes, strayPrompts: $strayPrompts, garbageReads: $garbageReads)';
}


}

/// @nodoc
abstract mixin class _$Obd2FramingStatsCopyWith<$Res> implements $Obd2FramingStatsCopyWith<$Res> {
  factory _$Obd2FramingStatsCopyWith(_Obd2FramingStats value, $Res Function(_Obd2FramingStats) _then) = __$Obd2FramingStatsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'pf') int partialFrames,@JsonKey(name: 'lo') int leftoverBytes,@JsonKey(name: 'sp') int strayPrompts,@JsonKey(name: 'gb') int garbageReads
});




}
/// @nodoc
class __$Obd2FramingStatsCopyWithImpl<$Res>
    implements _$Obd2FramingStatsCopyWith<$Res> {
  __$Obd2FramingStatsCopyWithImpl(this._self, this._then);

  final _Obd2FramingStats _self;
  final $Res Function(_Obd2FramingStats) _then;

/// Create a copy of Obd2FramingStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? partialFrames = null,Object? leftoverBytes = null,Object? strayPrompts = null,Object? garbageReads = null,}) {
  return _then(_Obd2FramingStats(
partialFrames: null == partialFrames ? _self.partialFrames : partialFrames // ignore: cast_nullable_to_non_nullable
as int,leftoverBytes: null == leftoverBytes ? _self.leftoverBytes : leftoverBytes // ignore: cast_nullable_to_non_nullable
as int,strayPrompts: null == strayPrompts ? _self.strayPrompts : strayPrompts // ignore: cast_nullable_to_non_nullable
as int,garbageReads: null == garbageReads ? _self.garbageReads : garbageReads // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
