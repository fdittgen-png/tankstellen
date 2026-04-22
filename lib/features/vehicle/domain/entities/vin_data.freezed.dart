// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vin_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VinData {

 String get vin; String? get make; String? get model; int? get modelYear; double? get displacementL; int? get cylinderCount; String? get fuelTypePrimary; int? get engineHp; int? get gvwrLbs;// ISO country or human-readable country name from the WMI offline
// table. Only populated on the wmiOffline path — vPIC doesn't
// expose a country field directly in the decoded variables we
// parse.
 String? get country;@VinDataSourceJsonConverter() VinDataSource get source;
/// Create a copy of VinData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VinDataCopyWith<VinData> get copyWith => _$VinDataCopyWithImpl<VinData>(this as VinData, _$identity);

  /// Serializes this VinData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VinData&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.modelYear, modelYear) || other.modelYear == modelYear)&&(identical(other.displacementL, displacementL) || other.displacementL == displacementL)&&(identical(other.cylinderCount, cylinderCount) || other.cylinderCount == cylinderCount)&&(identical(other.fuelTypePrimary, fuelTypePrimary) || other.fuelTypePrimary == fuelTypePrimary)&&(identical(other.engineHp, engineHp) || other.engineHp == engineHp)&&(identical(other.gvwrLbs, gvwrLbs) || other.gvwrLbs == gvwrLbs)&&(identical(other.country, country) || other.country == country)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vin,make,model,modelYear,displacementL,cylinderCount,fuelTypePrimary,engineHp,gvwrLbs,country,source);

@override
String toString() {
  return 'VinData(vin: $vin, make: $make, model: $model, modelYear: $modelYear, displacementL: $displacementL, cylinderCount: $cylinderCount, fuelTypePrimary: $fuelTypePrimary, engineHp: $engineHp, gvwrLbs: $gvwrLbs, country: $country, source: $source)';
}


}

/// @nodoc
abstract mixin class $VinDataCopyWith<$Res>  {
  factory $VinDataCopyWith(VinData value, $Res Function(VinData) _then) = _$VinDataCopyWithImpl;
@useResult
$Res call({
 String vin, String? make, String? model, int? modelYear, double? displacementL, int? cylinderCount, String? fuelTypePrimary, int? engineHp, int? gvwrLbs, String? country,@VinDataSourceJsonConverter() VinDataSource source
});




}
/// @nodoc
class _$VinDataCopyWithImpl<$Res>
    implements $VinDataCopyWith<$Res> {
  _$VinDataCopyWithImpl(this._self, this._then);

  final VinData _self;
  final $Res Function(VinData) _then;

/// Create a copy of VinData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vin = null,Object? make = freezed,Object? model = freezed,Object? modelYear = freezed,Object? displacementL = freezed,Object? cylinderCount = freezed,Object? fuelTypePrimary = freezed,Object? engineHp = freezed,Object? gvwrLbs = freezed,Object? country = freezed,Object? source = null,}) {
  return _then(_self.copyWith(
vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,make: freezed == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,modelYear: freezed == modelYear ? _self.modelYear : modelYear // ignore: cast_nullable_to_non_nullable
as int?,displacementL: freezed == displacementL ? _self.displacementL : displacementL // ignore: cast_nullable_to_non_nullable
as double?,cylinderCount: freezed == cylinderCount ? _self.cylinderCount : cylinderCount // ignore: cast_nullable_to_non_nullable
as int?,fuelTypePrimary: freezed == fuelTypePrimary ? _self.fuelTypePrimary : fuelTypePrimary // ignore: cast_nullable_to_non_nullable
as String?,engineHp: freezed == engineHp ? _self.engineHp : engineHp // ignore: cast_nullable_to_non_nullable
as int?,gvwrLbs: freezed == gvwrLbs ? _self.gvwrLbs : gvwrLbs // ignore: cast_nullable_to_non_nullable
as int?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as VinDataSource,
  ));
}

}


/// Adds pattern-matching-related methods to [VinData].
extension VinDataPatterns on VinData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VinData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VinData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VinData value)  $default,){
final _that = this;
switch (_that) {
case _VinData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VinData value)?  $default,){
final _that = this;
switch (_that) {
case _VinData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String vin,  String? make,  String? model,  int? modelYear,  double? displacementL,  int? cylinderCount,  String? fuelTypePrimary,  int? engineHp,  int? gvwrLbs,  String? country, @VinDataSourceJsonConverter()  VinDataSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VinData() when $default != null:
return $default(_that.vin,_that.make,_that.model,_that.modelYear,_that.displacementL,_that.cylinderCount,_that.fuelTypePrimary,_that.engineHp,_that.gvwrLbs,_that.country,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String vin,  String? make,  String? model,  int? modelYear,  double? displacementL,  int? cylinderCount,  String? fuelTypePrimary,  int? engineHp,  int? gvwrLbs,  String? country, @VinDataSourceJsonConverter()  VinDataSource source)  $default,) {final _that = this;
switch (_that) {
case _VinData():
return $default(_that.vin,_that.make,_that.model,_that.modelYear,_that.displacementL,_that.cylinderCount,_that.fuelTypePrimary,_that.engineHp,_that.gvwrLbs,_that.country,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String vin,  String? make,  String? model,  int? modelYear,  double? displacementL,  int? cylinderCount,  String? fuelTypePrimary,  int? engineHp,  int? gvwrLbs,  String? country, @VinDataSourceJsonConverter()  VinDataSource source)?  $default,) {final _that = this;
switch (_that) {
case _VinData() when $default != null:
return $default(_that.vin,_that.make,_that.model,_that.modelYear,_that.displacementL,_that.cylinderCount,_that.fuelTypePrimary,_that.engineHp,_that.gvwrLbs,_that.country,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VinData extends VinData {
  const _VinData({required this.vin, this.make, this.model, this.modelYear, this.displacementL, this.cylinderCount, this.fuelTypePrimary, this.engineHp, this.gvwrLbs, this.country, @VinDataSourceJsonConverter() this.source = VinDataSource.invalid}): super._();
  factory _VinData.fromJson(Map<String, dynamic> json) => _$VinDataFromJson(json);

@override final  String vin;
@override final  String? make;
@override final  String? model;
@override final  int? modelYear;
@override final  double? displacementL;
@override final  int? cylinderCount;
@override final  String? fuelTypePrimary;
@override final  int? engineHp;
@override final  int? gvwrLbs;
// ISO country or human-readable country name from the WMI offline
// table. Only populated on the wmiOffline path — vPIC doesn't
// expose a country field directly in the decoded variables we
// parse.
@override final  String? country;
@override@JsonKey()@VinDataSourceJsonConverter() final  VinDataSource source;

/// Create a copy of VinData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VinDataCopyWith<_VinData> get copyWith => __$VinDataCopyWithImpl<_VinData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VinDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VinData&&(identical(other.vin, vin) || other.vin == vin)&&(identical(other.make, make) || other.make == make)&&(identical(other.model, model) || other.model == model)&&(identical(other.modelYear, modelYear) || other.modelYear == modelYear)&&(identical(other.displacementL, displacementL) || other.displacementL == displacementL)&&(identical(other.cylinderCount, cylinderCount) || other.cylinderCount == cylinderCount)&&(identical(other.fuelTypePrimary, fuelTypePrimary) || other.fuelTypePrimary == fuelTypePrimary)&&(identical(other.engineHp, engineHp) || other.engineHp == engineHp)&&(identical(other.gvwrLbs, gvwrLbs) || other.gvwrLbs == gvwrLbs)&&(identical(other.country, country) || other.country == country)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,vin,make,model,modelYear,displacementL,cylinderCount,fuelTypePrimary,engineHp,gvwrLbs,country,source);

@override
String toString() {
  return 'VinData(vin: $vin, make: $make, model: $model, modelYear: $modelYear, displacementL: $displacementL, cylinderCount: $cylinderCount, fuelTypePrimary: $fuelTypePrimary, engineHp: $engineHp, gvwrLbs: $gvwrLbs, country: $country, source: $source)';
}


}

/// @nodoc
abstract mixin class _$VinDataCopyWith<$Res> implements $VinDataCopyWith<$Res> {
  factory _$VinDataCopyWith(_VinData value, $Res Function(_VinData) _then) = __$VinDataCopyWithImpl;
@override @useResult
$Res call({
 String vin, String? make, String? model, int? modelYear, double? displacementL, int? cylinderCount, String? fuelTypePrimary, int? engineHp, int? gvwrLbs, String? country,@VinDataSourceJsonConverter() VinDataSource source
});




}
/// @nodoc
class __$VinDataCopyWithImpl<$Res>
    implements _$VinDataCopyWith<$Res> {
  __$VinDataCopyWithImpl(this._self, this._then);

  final _VinData _self;
  final $Res Function(_VinData) _then;

/// Create a copy of VinData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vin = null,Object? make = freezed,Object? model = freezed,Object? modelYear = freezed,Object? displacementL = freezed,Object? cylinderCount = freezed,Object? fuelTypePrimary = freezed,Object? engineHp = freezed,Object? gvwrLbs = freezed,Object? country = freezed,Object? source = null,}) {
  return _then(_VinData(
vin: null == vin ? _self.vin : vin // ignore: cast_nullable_to_non_nullable
as String,make: freezed == make ? _self.make : make // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,modelYear: freezed == modelYear ? _self.modelYear : modelYear // ignore: cast_nullable_to_non_nullable
as int?,displacementL: freezed == displacementL ? _self.displacementL : displacementL // ignore: cast_nullable_to_non_nullable
as double?,cylinderCount: freezed == cylinderCount ? _self.cylinderCount : cylinderCount // ignore: cast_nullable_to_non_nullable
as int?,fuelTypePrimary: freezed == fuelTypePrimary ? _self.fuelTypePrimary : fuelTypePrimary // ignore: cast_nullable_to_non_nullable
as String?,engineHp: freezed == engineHp ? _self.engineHp : engineHp // ignore: cast_nullable_to_non_nullable
as int?,gvwrLbs: freezed == gvwrLbs ? _self.gvwrLbs : gvwrLbs // ignore: cast_nullable_to_non_nullable
as int?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as VinDataSource,
  ));
}


}

// dart format on
