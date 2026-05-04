// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'broken_map_belief.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BrokenMapBelief {

/// EMA-smoothed confidence in [0.0, 1.0]. Updater clamps on every
/// step.
 double get confidence;/// Number of observations folded into [confidence]. Useful for
/// "verified" auto-clear (phase 2 of #1424 will gate on this).
 int get observationCount;/// Last time [BrokenMapBeliefUpdater.update] was called. Null when
/// the belief was just constructed and has never been updated.
 DateTime? get lastUpdate;/// Last reason that contributed a *strong* observation
/// (`observationScore > 0.5`). Sticky — only overwritten on the
/// next strong observation.
 BrokenMapReason get lastTrigger;
/// Create a copy of BrokenMapBelief
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrokenMapBeliefCopyWith<BrokenMapBelief> get copyWith => _$BrokenMapBeliefCopyWithImpl<BrokenMapBelief>(this as BrokenMapBelief, _$identity);

  /// Serializes this BrokenMapBelief to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrokenMapBelief&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.observationCount, observationCount) || other.observationCount == observationCount)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate)&&(identical(other.lastTrigger, lastTrigger) || other.lastTrigger == lastTrigger));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,confidence,observationCount,lastUpdate,lastTrigger);

@override
String toString() {
  return 'BrokenMapBelief(confidence: $confidence, observationCount: $observationCount, lastUpdate: $lastUpdate, lastTrigger: $lastTrigger)';
}


}

/// @nodoc
abstract mixin class $BrokenMapBeliefCopyWith<$Res>  {
  factory $BrokenMapBeliefCopyWith(BrokenMapBelief value, $Res Function(BrokenMapBelief) _then) = _$BrokenMapBeliefCopyWithImpl;
@useResult
$Res call({
 double confidence, int observationCount, DateTime? lastUpdate, BrokenMapReason lastTrigger
});




}
/// @nodoc
class _$BrokenMapBeliefCopyWithImpl<$Res>
    implements $BrokenMapBeliefCopyWith<$Res> {
  _$BrokenMapBeliefCopyWithImpl(this._self, this._then);

  final BrokenMapBelief _self;
  final $Res Function(BrokenMapBelief) _then;

/// Create a copy of BrokenMapBelief
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? confidence = null,Object? observationCount = null,Object? lastUpdate = freezed,Object? lastTrigger = null,}) {
  return _then(_self.copyWith(
confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,observationCount: null == observationCount ? _self.observationCount : observationCount // ignore: cast_nullable_to_non_nullable
as int,lastUpdate: freezed == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastTrigger: null == lastTrigger ? _self.lastTrigger : lastTrigger // ignore: cast_nullable_to_non_nullable
as BrokenMapReason,
  ));
}

}


/// Adds pattern-matching-related methods to [BrokenMapBelief].
extension BrokenMapBeliefPatterns on BrokenMapBelief {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrokenMapBelief value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrokenMapBelief() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrokenMapBelief value)  $default,){
final _that = this;
switch (_that) {
case _BrokenMapBelief():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrokenMapBelief value)?  $default,){
final _that = this;
switch (_that) {
case _BrokenMapBelief() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double confidence,  int observationCount,  DateTime? lastUpdate,  BrokenMapReason lastTrigger)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrokenMapBelief() when $default != null:
return $default(_that.confidence,_that.observationCount,_that.lastUpdate,_that.lastTrigger);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double confidence,  int observationCount,  DateTime? lastUpdate,  BrokenMapReason lastTrigger)  $default,) {final _that = this;
switch (_that) {
case _BrokenMapBelief():
return $default(_that.confidence,_that.observationCount,_that.lastUpdate,_that.lastTrigger);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double confidence,  int observationCount,  DateTime? lastUpdate,  BrokenMapReason lastTrigger)?  $default,) {final _that = this;
switch (_that) {
case _BrokenMapBelief() when $default != null:
return $default(_that.confidence,_that.observationCount,_that.lastUpdate,_that.lastTrigger);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BrokenMapBelief extends BrokenMapBelief {
  const _BrokenMapBelief({this.confidence = 0.0, this.observationCount = 0, this.lastUpdate, this.lastTrigger = BrokenMapReason.none}): super._();
  factory _BrokenMapBelief.fromJson(Map<String, dynamic> json) => _$BrokenMapBeliefFromJson(json);

/// EMA-smoothed confidence in [0.0, 1.0]. Updater clamps on every
/// step.
@override@JsonKey() final  double confidence;
/// Number of observations folded into [confidence]. Useful for
/// "verified" auto-clear (phase 2 of #1424 will gate on this).
@override@JsonKey() final  int observationCount;
/// Last time [BrokenMapBeliefUpdater.update] was called. Null when
/// the belief was just constructed and has never been updated.
@override final  DateTime? lastUpdate;
/// Last reason that contributed a *strong* observation
/// (`observationScore > 0.5`). Sticky — only overwritten on the
/// next strong observation.
@override@JsonKey() final  BrokenMapReason lastTrigger;

/// Create a copy of BrokenMapBelief
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrokenMapBeliefCopyWith<_BrokenMapBelief> get copyWith => __$BrokenMapBeliefCopyWithImpl<_BrokenMapBelief>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BrokenMapBeliefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrokenMapBelief&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.observationCount, observationCount) || other.observationCount == observationCount)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate)&&(identical(other.lastTrigger, lastTrigger) || other.lastTrigger == lastTrigger));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,confidence,observationCount,lastUpdate,lastTrigger);

@override
String toString() {
  return 'BrokenMapBelief(confidence: $confidence, observationCount: $observationCount, lastUpdate: $lastUpdate, lastTrigger: $lastTrigger)';
}


}

/// @nodoc
abstract mixin class _$BrokenMapBeliefCopyWith<$Res> implements $BrokenMapBeliefCopyWith<$Res> {
  factory _$BrokenMapBeliefCopyWith(_BrokenMapBelief value, $Res Function(_BrokenMapBelief) _then) = __$BrokenMapBeliefCopyWithImpl;
@override @useResult
$Res call({
 double confidence, int observationCount, DateTime? lastUpdate, BrokenMapReason lastTrigger
});




}
/// @nodoc
class __$BrokenMapBeliefCopyWithImpl<$Res>
    implements _$BrokenMapBeliefCopyWith<$Res> {
  __$BrokenMapBeliefCopyWithImpl(this._self, this._then);

  final _BrokenMapBelief _self;
  final $Res Function(_BrokenMapBelief) _then;

/// Create a copy of BrokenMapBelief
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? confidence = null,Object? observationCount = null,Object? lastUpdate = freezed,Object? lastTrigger = null,}) {
  return _then(_BrokenMapBelief(
confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,observationCount: null == observationCount ? _self.observationCount : observationCount // ignore: cast_nullable_to_non_nullable
as int,lastUpdate: freezed == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime?,lastTrigger: null == lastTrigger ? _self.lastTrigger : lastTrigger // ignore: cast_nullable_to_non_nullable
as BrokenMapReason,
  ));
}


}

// dart format on
