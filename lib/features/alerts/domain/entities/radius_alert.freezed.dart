// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'radius_alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RadiusAlert {

 String get id; String get fuelType; double get threshold; double get centerLat; double get centerLng; double get radiusKm; String get label; DateTime get createdAt; bool get enabled; int get frequencyPerDay;
/// Create a copy of RadiusAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RadiusAlertCopyWith<RadiusAlert> get copyWith => _$RadiusAlertCopyWithImpl<RadiusAlert>(this as RadiusAlert, _$identity);

  /// Serializes this RadiusAlert to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RadiusAlert&&(identical(other.id, id) || other.id == id)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.centerLat, centerLat) || other.centerLat == centerLat)&&(identical(other.centerLng, centerLng) || other.centerLng == centerLng)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.frequencyPerDay, frequencyPerDay) || other.frequencyPerDay == frequencyPerDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fuelType,threshold,centerLat,centerLng,radiusKm,label,createdAt,enabled,frequencyPerDay);

@override
String toString() {
  return 'RadiusAlert(id: $id, fuelType: $fuelType, threshold: $threshold, centerLat: $centerLat, centerLng: $centerLng, radiusKm: $radiusKm, label: $label, createdAt: $createdAt, enabled: $enabled, frequencyPerDay: $frequencyPerDay)';
}


}

/// @nodoc
abstract mixin class $RadiusAlertCopyWith<$Res>  {
  factory $RadiusAlertCopyWith(RadiusAlert value, $Res Function(RadiusAlert) _then) = _$RadiusAlertCopyWithImpl;
@useResult
$Res call({
 String id, String fuelType, double threshold, double centerLat, double centerLng, double radiusKm, String label, DateTime createdAt, bool enabled, int frequencyPerDay
});




}
/// @nodoc
class _$RadiusAlertCopyWithImpl<$Res>
    implements $RadiusAlertCopyWith<$Res> {
  _$RadiusAlertCopyWithImpl(this._self, this._then);

  final RadiusAlert _self;
  final $Res Function(RadiusAlert) _then;

/// Create a copy of RadiusAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fuelType = null,Object? threshold = null,Object? centerLat = null,Object? centerLng = null,Object? radiusKm = null,Object? label = null,Object? createdAt = null,Object? enabled = null,Object? frequencyPerDay = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as double,centerLat: null == centerLat ? _self.centerLat : centerLat // ignore: cast_nullable_to_non_nullable
as double,centerLng: null == centerLng ? _self.centerLng : centerLng // ignore: cast_nullable_to_non_nullable
as double,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,frequencyPerDay: null == frequencyPerDay ? _self.frequencyPerDay : frequencyPerDay // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RadiusAlert].
extension RadiusAlertPatterns on RadiusAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RadiusAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RadiusAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RadiusAlert value)  $default,){
final _that = this;
switch (_that) {
case _RadiusAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RadiusAlert value)?  $default,){
final _that = this;
switch (_that) {
case _RadiusAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fuelType,  double threshold,  double centerLat,  double centerLng,  double radiusKm,  String label,  DateTime createdAt,  bool enabled,  int frequencyPerDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RadiusAlert() when $default != null:
return $default(_that.id,_that.fuelType,_that.threshold,_that.centerLat,_that.centerLng,_that.radiusKm,_that.label,_that.createdAt,_that.enabled,_that.frequencyPerDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fuelType,  double threshold,  double centerLat,  double centerLng,  double radiusKm,  String label,  DateTime createdAt,  bool enabled,  int frequencyPerDay)  $default,) {final _that = this;
switch (_that) {
case _RadiusAlert():
return $default(_that.id,_that.fuelType,_that.threshold,_that.centerLat,_that.centerLng,_that.radiusKm,_that.label,_that.createdAt,_that.enabled,_that.frequencyPerDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fuelType,  double threshold,  double centerLat,  double centerLng,  double radiusKm,  String label,  DateTime createdAt,  bool enabled,  int frequencyPerDay)?  $default,) {final _that = this;
switch (_that) {
case _RadiusAlert() when $default != null:
return $default(_that.id,_that.fuelType,_that.threshold,_that.centerLat,_that.centerLng,_that.radiusKm,_that.label,_that.createdAt,_that.enabled,_that.frequencyPerDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RadiusAlert implements RadiusAlert {
  const _RadiusAlert({required this.id, required this.fuelType, required this.threshold, required this.centerLat, required this.centerLng, required this.radiusKm, required this.label, required this.createdAt, this.enabled = true, this.frequencyPerDay = 1});
  factory _RadiusAlert.fromJson(Map<String, dynamic> json) => _$RadiusAlertFromJson(json);

@override final  String id;
@override final  String fuelType;
@override final  double threshold;
@override final  double centerLat;
@override final  double centerLng;
@override final  double radiusKm;
@override final  String label;
@override final  DateTime createdAt;
@override@JsonKey() final  bool enabled;
@override@JsonKey() final  int frequencyPerDay;

/// Create a copy of RadiusAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RadiusAlertCopyWith<_RadiusAlert> get copyWith => __$RadiusAlertCopyWithImpl<_RadiusAlert>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RadiusAlertToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RadiusAlert&&(identical(other.id, id) || other.id == id)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.threshold, threshold) || other.threshold == threshold)&&(identical(other.centerLat, centerLat) || other.centerLat == centerLat)&&(identical(other.centerLng, centerLng) || other.centerLng == centerLng)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.frequencyPerDay, frequencyPerDay) || other.frequencyPerDay == frequencyPerDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fuelType,threshold,centerLat,centerLng,radiusKm,label,createdAt,enabled,frequencyPerDay);

@override
String toString() {
  return 'RadiusAlert(id: $id, fuelType: $fuelType, threshold: $threshold, centerLat: $centerLat, centerLng: $centerLng, radiusKm: $radiusKm, label: $label, createdAt: $createdAt, enabled: $enabled, frequencyPerDay: $frequencyPerDay)';
}


}

/// @nodoc
abstract mixin class _$RadiusAlertCopyWith<$Res> implements $RadiusAlertCopyWith<$Res> {
  factory _$RadiusAlertCopyWith(_RadiusAlert value, $Res Function(_RadiusAlert) _then) = __$RadiusAlertCopyWithImpl;
@override @useResult
$Res call({
 String id, String fuelType, double threshold, double centerLat, double centerLng, double radiusKm, String label, DateTime createdAt, bool enabled, int frequencyPerDay
});




}
/// @nodoc
class __$RadiusAlertCopyWithImpl<$Res>
    implements _$RadiusAlertCopyWith<$Res> {
  __$RadiusAlertCopyWithImpl(this._self, this._then);

  final _RadiusAlert _self;
  final $Res Function(_RadiusAlert) _then;

/// Create a copy of RadiusAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fuelType = null,Object? threshold = null,Object? centerLat = null,Object? centerLng = null,Object? radiusKm = null,Object? label = null,Object? createdAt = null,Object? enabled = null,Object? frequencyPerDay = null,}) {
  return _then(_RadiusAlert(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String,threshold: null == threshold ? _self.threshold : threshold // ignore: cast_nullable_to_non_nullable
as double,centerLat: null == centerLat ? _self.centerLat : centerLat // ignore: cast_nullable_to_non_nullable
as double,centerLng: null == centerLng ? _self.centerLng : centerLng // ignore: cast_nullable_to_non_nullable
as double,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,frequencyPerDay: null == frequencyPerDay ? _self.frequencyPerDay : frequencyPerDay // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
