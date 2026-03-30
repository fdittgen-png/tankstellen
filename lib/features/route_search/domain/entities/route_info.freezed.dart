// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'route_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RouteInfo {

 List<LatLng> get geometry;// Full polyline coordinates
 double get distanceKm; double get durationMinutes; List<LatLng> get samplePoints;
/// Create a copy of RouteInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteInfoCopyWith<RouteInfo> get copyWith => _$RouteInfoCopyWithImpl<RouteInfo>(this as RouteInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteInfo&&const DeepCollectionEquality().equals(other.geometry, geometry)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&const DeepCollectionEquality().equals(other.samplePoints, samplePoints));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(geometry),distanceKm,durationMinutes,const DeepCollectionEquality().hash(samplePoints));

@override
String toString() {
  return 'RouteInfo(geometry: $geometry, distanceKm: $distanceKm, durationMinutes: $durationMinutes, samplePoints: $samplePoints)';
}


}

/// @nodoc
abstract mixin class $RouteInfoCopyWith<$Res>  {
  factory $RouteInfoCopyWith(RouteInfo value, $Res Function(RouteInfo) _then) = _$RouteInfoCopyWithImpl;
@useResult
$Res call({
 List<LatLng> geometry, double distanceKm, double durationMinutes, List<LatLng> samplePoints
});




}
/// @nodoc
class _$RouteInfoCopyWithImpl<$Res>
    implements $RouteInfoCopyWith<$Res> {
  _$RouteInfoCopyWithImpl(this._self, this._then);

  final RouteInfo _self;
  final $Res Function(RouteInfo) _then;

/// Create a copy of RouteInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? geometry = null,Object? distanceKm = null,Object? durationMinutes = null,Object? samplePoints = null,}) {
  return _then(_self.copyWith(
geometry: null == geometry ? _self.geometry : geometry // ignore: cast_nullable_to_non_nullable
as List<LatLng>,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as double,samplePoints: null == samplePoints ? _self.samplePoints : samplePoints // ignore: cast_nullable_to_non_nullable
as List<LatLng>,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteInfo].
extension RouteInfoPatterns on RouteInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteInfo value)  $default,){
final _that = this;
switch (_that) {
case _RouteInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteInfo value)?  $default,){
final _that = this;
switch (_that) {
case _RouteInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LatLng> geometry,  double distanceKm,  double durationMinutes,  List<LatLng> samplePoints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteInfo() when $default != null:
return $default(_that.geometry,_that.distanceKm,_that.durationMinutes,_that.samplePoints);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LatLng> geometry,  double distanceKm,  double durationMinutes,  List<LatLng> samplePoints)  $default,) {final _that = this;
switch (_that) {
case _RouteInfo():
return $default(_that.geometry,_that.distanceKm,_that.durationMinutes,_that.samplePoints);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LatLng> geometry,  double distanceKm,  double durationMinutes,  List<LatLng> samplePoints)?  $default,) {final _that = this;
switch (_that) {
case _RouteInfo() when $default != null:
return $default(_that.geometry,_that.distanceKm,_that.durationMinutes,_that.samplePoints);case _:
  return null;

}
}

}

/// @nodoc


class _RouteInfo implements RouteInfo {
  const _RouteInfo({required final  List<LatLng> geometry, required this.distanceKm, required this.durationMinutes, required final  List<LatLng> samplePoints}): _geometry = geometry,_samplePoints = samplePoints;
  

 final  List<LatLng> _geometry;
@override List<LatLng> get geometry {
  if (_geometry is EqualUnmodifiableListView) return _geometry;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_geometry);
}

// Full polyline coordinates
@override final  double distanceKm;
@override final  double durationMinutes;
 final  List<LatLng> _samplePoints;
@override List<LatLng> get samplePoints {
  if (_samplePoints is EqualUnmodifiableListView) return _samplePoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_samplePoints);
}


/// Create a copy of RouteInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteInfoCopyWith<_RouteInfo> get copyWith => __$RouteInfoCopyWithImpl<_RouteInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteInfo&&const DeepCollectionEquality().equals(other._geometry, _geometry)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&const DeepCollectionEquality().equals(other._samplePoints, _samplePoints));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_geometry),distanceKm,durationMinutes,const DeepCollectionEquality().hash(_samplePoints));

@override
String toString() {
  return 'RouteInfo(geometry: $geometry, distanceKm: $distanceKm, durationMinutes: $durationMinutes, samplePoints: $samplePoints)';
}


}

/// @nodoc
abstract mixin class _$RouteInfoCopyWith<$Res> implements $RouteInfoCopyWith<$Res> {
  factory _$RouteInfoCopyWith(_RouteInfo value, $Res Function(_RouteInfo) _then) = __$RouteInfoCopyWithImpl;
@override @useResult
$Res call({
 List<LatLng> geometry, double distanceKm, double durationMinutes, List<LatLng> samplePoints
});




}
/// @nodoc
class __$RouteInfoCopyWithImpl<$Res>
    implements _$RouteInfoCopyWith<$Res> {
  __$RouteInfoCopyWithImpl(this._self, this._then);

  final _RouteInfo _self;
  final $Res Function(_RouteInfo) _then;

/// Create a copy of RouteInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? geometry = null,Object? distanceKm = null,Object? durationMinutes = null,Object? samplePoints = null,}) {
  return _then(_RouteInfo(
geometry: null == geometry ? _self._geometry : geometry // ignore: cast_nullable_to_non_nullable
as List<LatLng>,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as double,samplePoints: null == samplePoints ? _self._samplePoints : samplePoints // ignore: cast_nullable_to_non_nullable
as List<LatLng>,
  ));
}


}

/// @nodoc
mixin _$RouteWaypoint {

 double get lat; double get lng; String get label;
/// Create a copy of RouteWaypoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RouteWaypointCopyWith<RouteWaypoint> get copyWith => _$RouteWaypointCopyWithImpl<RouteWaypoint>(this as RouteWaypoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RouteWaypoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,lat,lng,label);

@override
String toString() {
  return 'RouteWaypoint(lat: $lat, lng: $lng, label: $label)';
}


}

/// @nodoc
abstract mixin class $RouteWaypointCopyWith<$Res>  {
  factory $RouteWaypointCopyWith(RouteWaypoint value, $Res Function(RouteWaypoint) _then) = _$RouteWaypointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, String label
});




}
/// @nodoc
class _$RouteWaypointCopyWithImpl<$Res>
    implements $RouteWaypointCopyWith<$Res> {
  _$RouteWaypointCopyWithImpl(this._self, this._then);

  final RouteWaypoint _self;
  final $Res Function(RouteWaypoint) _then;

/// Create a copy of RouteWaypoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? label = null,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RouteWaypoint].
extension RouteWaypointPatterns on RouteWaypoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RouteWaypoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RouteWaypoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RouteWaypoint value)  $default,){
final _that = this;
switch (_that) {
case _RouteWaypoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RouteWaypoint value)?  $default,){
final _that = this;
switch (_that) {
case _RouteWaypoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RouteWaypoint() when $default != null:
return $default(_that.lat,_that.lng,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  String label)  $default,) {final _that = this;
switch (_that) {
case _RouteWaypoint():
return $default(_that.lat,_that.lng,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  String label)?  $default,) {final _that = this;
switch (_that) {
case _RouteWaypoint() when $default != null:
return $default(_that.lat,_that.lng,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _RouteWaypoint implements RouteWaypoint {
  const _RouteWaypoint({required this.lat, required this.lng, required this.label});
  

@override final  double lat;
@override final  double lng;
@override final  String label;

/// Create a copy of RouteWaypoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RouteWaypointCopyWith<_RouteWaypoint> get copyWith => __$RouteWaypointCopyWithImpl<_RouteWaypoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RouteWaypoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,lat,lng,label);

@override
String toString() {
  return 'RouteWaypoint(lat: $lat, lng: $lng, label: $label)';
}


}

/// @nodoc
abstract mixin class _$RouteWaypointCopyWith<$Res> implements $RouteWaypointCopyWith<$Res> {
  factory _$RouteWaypointCopyWith(_RouteWaypoint value, $Res Function(_RouteWaypoint) _then) = __$RouteWaypointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, String label
});




}
/// @nodoc
class __$RouteWaypointCopyWithImpl<$Res>
    implements _$RouteWaypointCopyWith<$Res> {
  __$RouteWaypointCopyWithImpl(this._self, this._then);

  final _RouteWaypoint _self;
  final $Res Function(_RouteWaypoint) _then;

/// Create a copy of RouteWaypoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? label = null,}) {
  return _then(_RouteWaypoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
