// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchParams {

 double get lat; double get lng; double get radiusKm; FuelType get fuelType; SortBy get sortBy; String? get postalCode; String? get locationName;
/// Create a copy of SearchParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchParamsCopyWith<SearchParams> get copyWith => _$SearchParamsCopyWithImpl<SearchParams>(this as SearchParams, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchParams&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.locationName, locationName) || other.locationName == locationName));
}


@override
int get hashCode => Object.hash(runtimeType,lat,lng,radiusKm,fuelType,sortBy,postalCode,locationName);

@override
String toString() {
  return 'SearchParams(lat: $lat, lng: $lng, radiusKm: $radiusKm, fuelType: $fuelType, sortBy: $sortBy, postalCode: $postalCode, locationName: $locationName)';
}


}

/// @nodoc
abstract mixin class $SearchParamsCopyWith<$Res>  {
  factory $SearchParamsCopyWith(SearchParams value, $Res Function(SearchParams) _then) = _$SearchParamsCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, double radiusKm, FuelType fuelType, SortBy sortBy, String? postalCode, String? locationName
});




}
/// @nodoc
class _$SearchParamsCopyWithImpl<$Res>
    implements $SearchParamsCopyWith<$Res> {
  _$SearchParamsCopyWithImpl(this._self, this._then);

  final SearchParams _self;
  final $Res Function(SearchParams) _then;

/// Create a copy of SearchParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? radiusKm = null,Object? fuelType = null,Object? sortBy = null,Object? postalCode = freezed,Object? locationName = freezed,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortBy,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchParams].
extension SearchParamsPatterns on SearchParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchParams value)  $default,){
final _that = this;
switch (_that) {
case _SearchParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchParams value)?  $default,){
final _that = this;
switch (_that) {
case _SearchParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  double radiusKm,  FuelType fuelType,  SortBy sortBy,  String? postalCode,  String? locationName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchParams() when $default != null:
return $default(_that.lat,_that.lng,_that.radiusKm,_that.fuelType,_that.sortBy,_that.postalCode,_that.locationName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  double radiusKm,  FuelType fuelType,  SortBy sortBy,  String? postalCode,  String? locationName)  $default,) {final _that = this;
switch (_that) {
case _SearchParams():
return $default(_that.lat,_that.lng,_that.radiusKm,_that.fuelType,_that.sortBy,_that.postalCode,_that.locationName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  double radiusKm,  FuelType fuelType,  SortBy sortBy,  String? postalCode,  String? locationName)?  $default,) {final _that = this;
switch (_that) {
case _SearchParams() when $default != null:
return $default(_that.lat,_that.lng,_that.radiusKm,_that.fuelType,_that.sortBy,_that.postalCode,_that.locationName);case _:
  return null;

}
}

}

/// @nodoc


class _SearchParams implements SearchParams {
  const _SearchParams({required this.lat, required this.lng, this.radiusKm = 10.0, this.fuelType = FuelType.all, this.sortBy = SortBy.price, this.postalCode, this.locationName});
  

@override final  double lat;
@override final  double lng;
@override@JsonKey() final  double radiusKm;
@override@JsonKey() final  FuelType fuelType;
@override@JsonKey() final  SortBy sortBy;
@override final  String? postalCode;
@override final  String? locationName;

/// Create a copy of SearchParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchParamsCopyWith<_SearchParams> get copyWith => __$SearchParamsCopyWithImpl<_SearchParams>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchParams&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.locationName, locationName) || other.locationName == locationName));
}


@override
int get hashCode => Object.hash(runtimeType,lat,lng,radiusKm,fuelType,sortBy,postalCode,locationName);

@override
String toString() {
  return 'SearchParams(lat: $lat, lng: $lng, radiusKm: $radiusKm, fuelType: $fuelType, sortBy: $sortBy, postalCode: $postalCode, locationName: $locationName)';
}


}

/// @nodoc
abstract mixin class _$SearchParamsCopyWith<$Res> implements $SearchParamsCopyWith<$Res> {
  factory _$SearchParamsCopyWith(_SearchParams value, $Res Function(_SearchParams) _then) = __$SearchParamsCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, double radiusKm, FuelType fuelType, SortBy sortBy, String? postalCode, String? locationName
});




}
/// @nodoc
class __$SearchParamsCopyWithImpl<$Res>
    implements _$SearchParamsCopyWith<$Res> {
  __$SearchParamsCopyWithImpl(this._self, this._then);

  final _SearchParams _self;
  final $Res Function(_SearchParams) _then;

/// Create a copy of SearchParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? radiusKm = null,Object? fuelType = null,Object? sortBy = null,Object? postalCode = freezed,Object? locationName = freezed,}) {
  return _then(_SearchParams(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as FuelType,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as SortBy,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
