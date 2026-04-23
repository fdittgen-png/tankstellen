// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PriceSnapshot {

 String get stationId; String get fuelType; double get price; DateTime get timestamp; double get lat; double get lng;
/// Create a copy of PriceSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceSnapshotCopyWith<PriceSnapshot> get copyWith => _$PriceSnapshotCopyWithImpl<PriceSnapshot>(this as PriceSnapshot, _$identity);

  /// Serializes this PriceSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceSnapshot&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.price, price) || other.price == price)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stationId,fuelType,price,timestamp,lat,lng);

@override
String toString() {
  return 'PriceSnapshot(stationId: $stationId, fuelType: $fuelType, price: $price, timestamp: $timestamp, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class $PriceSnapshotCopyWith<$Res>  {
  factory $PriceSnapshotCopyWith(PriceSnapshot value, $Res Function(PriceSnapshot) _then) = _$PriceSnapshotCopyWithImpl;
@useResult
$Res call({
 String stationId, String fuelType, double price, DateTime timestamp, double lat, double lng
});




}
/// @nodoc
class _$PriceSnapshotCopyWithImpl<$Res>
    implements $PriceSnapshotCopyWith<$Res> {
  _$PriceSnapshotCopyWithImpl(this._self, this._then);

  final PriceSnapshot _self;
  final $Res Function(PriceSnapshot) _then;

/// Create a copy of PriceSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stationId = null,Object? fuelType = null,Object? price = null,Object? timestamp = null,Object? lat = null,Object? lng = null,}) {
  return _then(_self.copyWith(
stationId: null == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceSnapshot].
extension PriceSnapshotPatterns on PriceSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _PriceSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _PriceSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stationId,  String fuelType,  double price,  DateTime timestamp,  double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceSnapshot() when $default != null:
return $default(_that.stationId,_that.fuelType,_that.price,_that.timestamp,_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stationId,  String fuelType,  double price,  DateTime timestamp,  double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _PriceSnapshot():
return $default(_that.stationId,_that.fuelType,_that.price,_that.timestamp,_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stationId,  String fuelType,  double price,  DateTime timestamp,  double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _PriceSnapshot() when $default != null:
return $default(_that.stationId,_that.fuelType,_that.price,_that.timestamp,_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceSnapshot implements PriceSnapshot {
  const _PriceSnapshot({required this.stationId, required this.fuelType, required this.price, required this.timestamp, required this.lat, required this.lng});
  factory _PriceSnapshot.fromJson(Map<String, dynamic> json) => _$PriceSnapshotFromJson(json);

@override final  String stationId;
@override final  String fuelType;
@override final  double price;
@override final  DateTime timestamp;
@override final  double lat;
@override final  double lng;

/// Create a copy of PriceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceSnapshotCopyWith<_PriceSnapshot> get copyWith => __$PriceSnapshotCopyWithImpl<_PriceSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceSnapshot&&(identical(other.stationId, stationId) || other.stationId == stationId)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.price, price) || other.price == price)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stationId,fuelType,price,timestamp,lat,lng);

@override
String toString() {
  return 'PriceSnapshot(stationId: $stationId, fuelType: $fuelType, price: $price, timestamp: $timestamp, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$PriceSnapshotCopyWith<$Res> implements $PriceSnapshotCopyWith<$Res> {
  factory _$PriceSnapshotCopyWith(_PriceSnapshot value, $Res Function(_PriceSnapshot) _then) = __$PriceSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String stationId, String fuelType, double price, DateTime timestamp, double lat, double lng
});




}
/// @nodoc
class __$PriceSnapshotCopyWithImpl<$Res>
    implements _$PriceSnapshotCopyWith<$Res> {
  __$PriceSnapshotCopyWithImpl(this._self, this._then);

  final _PriceSnapshot _self;
  final $Res Function(_PriceSnapshot) _then;

/// Create a copy of PriceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stationId = null,Object? fuelType = null,Object? price = null,Object? timestamp = null,Object? lat = null,Object? lng = null,}) {
  return _then(_PriceSnapshot(
stationId: null == stationId ? _self.stationId : stationId // ignore: cast_nullable_to_non_nullable
as String,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
