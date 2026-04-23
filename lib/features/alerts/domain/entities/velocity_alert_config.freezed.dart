// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'velocity_alert_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VelocityAlertConfig {

@FuelTypeJsonConverter() FuelType get fuelType; double get minDropCents; int get minStations; double get radiusKm; int get cooldownHours;
/// Create a copy of VelocityAlertConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VelocityAlertConfigCopyWith<VelocityAlertConfig> get copyWith => _$VelocityAlertConfigCopyWithImpl<VelocityAlertConfig>(this as VelocityAlertConfig, _$identity);

  /// Serializes this VelocityAlertConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VelocityAlertConfig&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.minDropCents, minDropCents) || other.minDropCents == minDropCents)&&(identical(other.minStations, minStations) || other.minStations == minStations)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&(identical(other.cooldownHours, cooldownHours) || other.cooldownHours == cooldownHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fuelType,minDropCents,minStations,radiusKm,cooldownHours);

@override
String toString() {
  return 'VelocityAlertConfig(fuelType: $fuelType, minDropCents: $minDropCents, minStations: $minStations, radiusKm: $radiusKm, cooldownHours: $cooldownHours)';
}


}

/// @nodoc
abstract mixin class $VelocityAlertConfigCopyWith<$Res>  {
  factory $VelocityAlertConfigCopyWith(VelocityAlertConfig value, $Res Function(VelocityAlertConfig) _then) = _$VelocityAlertConfigCopyWithImpl;
@useResult
$Res call({
@FuelTypeJsonConverter() FuelType fuelType, double minDropCents, int minStations, double radiusKm, int cooldownHours
});




}
/// @nodoc
class _$VelocityAlertConfigCopyWithImpl<$Res>
    implements $VelocityAlertConfigCopyWith<$Res> {
  _$VelocityAlertConfigCopyWithImpl(this._self, this._then);

  final VelocityAlertConfig _self;
  final $Res Function(VelocityAlertConfig) _then;

/// Create a copy of VelocityAlertConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fuelType = null,Object? minDropCents = null,Object? minStations = null,Object? radiusKm = null,Object? cooldownHours = null,}) {
  return _then(_self.copyWith(
fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,minDropCents: null == minDropCents ? _self.minDropCents : minDropCents // ignore: cast_nullable_to_non_nullable
as double,minStations: null == minStations ? _self.minStations : minStations // ignore: cast_nullable_to_non_nullable
as int,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,cooldownHours: null == cooldownHours ? _self.cooldownHours : cooldownHours // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VelocityAlertConfig].
extension VelocityAlertConfigPatterns on VelocityAlertConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VelocityAlertConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VelocityAlertConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VelocityAlertConfig value)  $default,){
final _that = this;
switch (_that) {
case _VelocityAlertConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VelocityAlertConfig value)?  $default,){
final _that = this;
switch (_that) {
case _VelocityAlertConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@FuelTypeJsonConverter()  FuelType fuelType,  double minDropCents,  int minStations,  double radiusKm,  int cooldownHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VelocityAlertConfig() when $default != null:
return $default(_that.fuelType,_that.minDropCents,_that.minStations,_that.radiusKm,_that.cooldownHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@FuelTypeJsonConverter()  FuelType fuelType,  double minDropCents,  int minStations,  double radiusKm,  int cooldownHours)  $default,) {final _that = this;
switch (_that) {
case _VelocityAlertConfig():
return $default(_that.fuelType,_that.minDropCents,_that.minStations,_that.radiusKm,_that.cooldownHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@FuelTypeJsonConverter()  FuelType fuelType,  double minDropCents,  int minStations,  double radiusKm,  int cooldownHours)?  $default,) {final _that = this;
switch (_that) {
case _VelocityAlertConfig() when $default != null:
return $default(_that.fuelType,_that.minDropCents,_that.minStations,_that.radiusKm,_that.cooldownHours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VelocityAlertConfig implements VelocityAlertConfig {
  const _VelocityAlertConfig({@FuelTypeJsonConverter() required this.fuelType, this.minDropCents = 3, this.minStations = 2, this.radiusKm = 15, this.cooldownHours = 6});
  factory _VelocityAlertConfig.fromJson(Map<String, dynamic> json) => _$VelocityAlertConfigFromJson(json);

@override@FuelTypeJsonConverter() final  FuelType fuelType;
@override@JsonKey() final  double minDropCents;
@override@JsonKey() final  int minStations;
@override@JsonKey() final  double radiusKm;
@override@JsonKey() final  int cooldownHours;

/// Create a copy of VelocityAlertConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VelocityAlertConfigCopyWith<_VelocityAlertConfig> get copyWith => __$VelocityAlertConfigCopyWithImpl<_VelocityAlertConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VelocityAlertConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VelocityAlertConfig&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.minDropCents, minDropCents) || other.minDropCents == minDropCents)&&(identical(other.minStations, minStations) || other.minStations == minStations)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&(identical(other.cooldownHours, cooldownHours) || other.cooldownHours == cooldownHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fuelType,minDropCents,minStations,radiusKm,cooldownHours);

@override
String toString() {
  return 'VelocityAlertConfig(fuelType: $fuelType, minDropCents: $minDropCents, minStations: $minStations, radiusKm: $radiusKm, cooldownHours: $cooldownHours)';
}


}

/// @nodoc
abstract mixin class _$VelocityAlertConfigCopyWith<$Res> implements $VelocityAlertConfigCopyWith<$Res> {
  factory _$VelocityAlertConfigCopyWith(_VelocityAlertConfig value, $Res Function(_VelocityAlertConfig) _then) = __$VelocityAlertConfigCopyWithImpl;
@override @useResult
$Res call({
@FuelTypeJsonConverter() FuelType fuelType, double minDropCents, int minStations, double radiusKm, int cooldownHours
});




}
/// @nodoc
class __$VelocityAlertConfigCopyWithImpl<$Res>
    implements _$VelocityAlertConfigCopyWith<$Res> {
  __$VelocityAlertConfigCopyWithImpl(this._self, this._then);

  final _VelocityAlertConfig _self;
  final $Res Function(_VelocityAlertConfig) _then;

/// Create a copy of VelocityAlertConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fuelType = null,Object? minDropCents = null,Object? minStations = null,Object? radiusKm = null,Object? cooldownHours = null,}) {
  return _then(_VelocityAlertConfig(
fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,minDropCents: null == minDropCents ? _self.minDropCents : minDropCents // ignore: cast_nullable_to_non_nullable
as double,minStations: null == minStations ? _self.minStations : minStations // ignore: cast_nullable_to_non_nullable
as int,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,cooldownHours: null == cooldownHours ? _self.cooldownHours : cooldownHours // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
