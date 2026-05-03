// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'traffic_signal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrafficSignal {

 String get id; double get lat; double get lng; String? get crossing; String? get highway;
/// Create a copy of TrafficSignal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrafficSignalCopyWith<TrafficSignal> get copyWith => _$TrafficSignalCopyWithImpl<TrafficSignal>(this as TrafficSignal, _$identity);

  /// Serializes this TrafficSignal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrafficSignal&&(identical(other.id, id) || other.id == id)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.crossing, crossing) || other.crossing == crossing)&&(identical(other.highway, highway) || other.highway == highway));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lat,lng,crossing,highway);

@override
String toString() {
  return 'TrafficSignal(id: $id, lat: $lat, lng: $lng, crossing: $crossing, highway: $highway)';
}


}

/// @nodoc
abstract mixin class $TrafficSignalCopyWith<$Res>  {
  factory $TrafficSignalCopyWith(TrafficSignal value, $Res Function(TrafficSignal) _then) = _$TrafficSignalCopyWithImpl;
@useResult
$Res call({
 String id, double lat, double lng, String? crossing, String? highway
});




}
/// @nodoc
class _$TrafficSignalCopyWithImpl<$Res>
    implements $TrafficSignalCopyWith<$Res> {
  _$TrafficSignalCopyWithImpl(this._self, this._then);

  final TrafficSignal _self;
  final $Res Function(TrafficSignal) _then;

/// Create a copy of TrafficSignal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lat = null,Object? lng = null,Object? crossing = freezed,Object? highway = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,crossing: freezed == crossing ? _self.crossing : crossing // ignore: cast_nullable_to_non_nullable
as String?,highway: freezed == highway ? _self.highway : highway // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrafficSignal].
extension TrafficSignalPatterns on TrafficSignal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrafficSignal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrafficSignal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrafficSignal value)  $default,){
final _that = this;
switch (_that) {
case _TrafficSignal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrafficSignal value)?  $default,){
final _that = this;
switch (_that) {
case _TrafficSignal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  double lat,  double lng,  String? crossing,  String? highway)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrafficSignal() when $default != null:
return $default(_that.id,_that.lat,_that.lng,_that.crossing,_that.highway);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  double lat,  double lng,  String? crossing,  String? highway)  $default,) {final _that = this;
switch (_that) {
case _TrafficSignal():
return $default(_that.id,_that.lat,_that.lng,_that.crossing,_that.highway);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  double lat,  double lng,  String? crossing,  String? highway)?  $default,) {final _that = this;
switch (_that) {
case _TrafficSignal() when $default != null:
return $default(_that.id,_that.lat,_that.lng,_that.crossing,_that.highway);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrafficSignal implements TrafficSignal {
  const _TrafficSignal({required this.id, required this.lat, required this.lng, this.crossing, this.highway});
  factory _TrafficSignal.fromJson(Map<String, dynamic> json) => _$TrafficSignalFromJson(json);

@override final  String id;
@override final  double lat;
@override final  double lng;
@override final  String? crossing;
@override final  String? highway;

/// Create a copy of TrafficSignal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrafficSignalCopyWith<_TrafficSignal> get copyWith => __$TrafficSignalCopyWithImpl<_TrafficSignal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrafficSignalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrafficSignal&&(identical(other.id, id) || other.id == id)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.crossing, crossing) || other.crossing == crossing)&&(identical(other.highway, highway) || other.highway == highway));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,lat,lng,crossing,highway);

@override
String toString() {
  return 'TrafficSignal(id: $id, lat: $lat, lng: $lng, crossing: $crossing, highway: $highway)';
}


}

/// @nodoc
abstract mixin class _$TrafficSignalCopyWith<$Res> implements $TrafficSignalCopyWith<$Res> {
  factory _$TrafficSignalCopyWith(_TrafficSignal value, $Res Function(_TrafficSignal) _then) = __$TrafficSignalCopyWithImpl;
@override @useResult
$Res call({
 String id, double lat, double lng, String? crossing, String? highway
});




}
/// @nodoc
class __$TrafficSignalCopyWithImpl<$Res>
    implements _$TrafficSignalCopyWith<$Res> {
  __$TrafficSignalCopyWithImpl(this._self, this._then);

  final _TrafficSignal _self;
  final $Res Function(_TrafficSignal) _then;

/// Create a copy of TrafficSignal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lat = null,Object? lng = null,Object? crossing = freezed,Object? highway = freezed,}) {
  return _then(_TrafficSignal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,crossing: freezed == crossing ? _self.crossing : crossing // ignore: cast_nullable_to_non_nullable
as String?,highway: freezed == highway ? _self.highway : highway // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
