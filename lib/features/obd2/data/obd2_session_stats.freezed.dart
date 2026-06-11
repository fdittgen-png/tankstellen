// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'obd2_session_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

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
