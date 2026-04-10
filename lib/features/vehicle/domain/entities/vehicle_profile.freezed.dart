// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vehicle_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChargingPreferences {

 int get minSocPercent; int get maxSocPercent; List<String> get preferredNetworks;
/// Create a copy of ChargingPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingPreferencesCopyWith<ChargingPreferences> get copyWith => _$ChargingPreferencesCopyWithImpl<ChargingPreferences>(this as ChargingPreferences, _$identity);

  /// Serializes this ChargingPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingPreferences&&(identical(other.minSocPercent, minSocPercent) || other.minSocPercent == minSocPercent)&&(identical(other.maxSocPercent, maxSocPercent) || other.maxSocPercent == maxSocPercent)&&const DeepCollectionEquality().equals(other.preferredNetworks, preferredNetworks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minSocPercent,maxSocPercent,const DeepCollectionEquality().hash(preferredNetworks));

@override
String toString() {
  return 'ChargingPreferences(minSocPercent: $minSocPercent, maxSocPercent: $maxSocPercent, preferredNetworks: $preferredNetworks)';
}


}

/// @nodoc
abstract mixin class $ChargingPreferencesCopyWith<$Res>  {
  factory $ChargingPreferencesCopyWith(ChargingPreferences value, $Res Function(ChargingPreferences) _then) = _$ChargingPreferencesCopyWithImpl;
@useResult
$Res call({
 int minSocPercent, int maxSocPercent, List<String> preferredNetworks
});




}
/// @nodoc
class _$ChargingPreferencesCopyWithImpl<$Res>
    implements $ChargingPreferencesCopyWith<$Res> {
  _$ChargingPreferencesCopyWithImpl(this._self, this._then);

  final ChargingPreferences _self;
  final $Res Function(ChargingPreferences) _then;

/// Create a copy of ChargingPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minSocPercent = null,Object? maxSocPercent = null,Object? preferredNetworks = null,}) {
  return _then(_self.copyWith(
minSocPercent: null == minSocPercent ? _self.minSocPercent : minSocPercent // ignore: cast_nullable_to_non_nullable
as int,maxSocPercent: null == maxSocPercent ? _self.maxSocPercent : maxSocPercent // ignore: cast_nullable_to_non_nullable
as int,preferredNetworks: null == preferredNetworks ? _self.preferredNetworks : preferredNetworks // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChargingPreferences].
extension ChargingPreferencesPatterns on ChargingPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChargingPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChargingPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChargingPreferences value)  $default,){
final _that = this;
switch (_that) {
case _ChargingPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChargingPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _ChargingPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int minSocPercent,  int maxSocPercent,  List<String> preferredNetworks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingPreferences() when $default != null:
return $default(_that.minSocPercent,_that.maxSocPercent,_that.preferredNetworks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int minSocPercent,  int maxSocPercent,  List<String> preferredNetworks)  $default,) {final _that = this;
switch (_that) {
case _ChargingPreferences():
return $default(_that.minSocPercent,_that.maxSocPercent,_that.preferredNetworks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int minSocPercent,  int maxSocPercent,  List<String> preferredNetworks)?  $default,) {final _that = this;
switch (_that) {
case _ChargingPreferences() when $default != null:
return $default(_that.minSocPercent,_that.maxSocPercent,_that.preferredNetworks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingPreferences implements ChargingPreferences {
  const _ChargingPreferences({this.minSocPercent = 20, this.maxSocPercent = 80, final  List<String> preferredNetworks = const <String>[]}): _preferredNetworks = preferredNetworks;
  factory _ChargingPreferences.fromJson(Map<String, dynamic> json) => _$ChargingPreferencesFromJson(json);

@override@JsonKey() final  int minSocPercent;
@override@JsonKey() final  int maxSocPercent;
 final  List<String> _preferredNetworks;
@override@JsonKey() List<String> get preferredNetworks {
  if (_preferredNetworks is EqualUnmodifiableListView) return _preferredNetworks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredNetworks);
}


/// Create a copy of ChargingPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChargingPreferencesCopyWith<_ChargingPreferences> get copyWith => __$ChargingPreferencesCopyWithImpl<_ChargingPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChargingPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingPreferences&&(identical(other.minSocPercent, minSocPercent) || other.minSocPercent == minSocPercent)&&(identical(other.maxSocPercent, maxSocPercent) || other.maxSocPercent == maxSocPercent)&&const DeepCollectionEquality().equals(other._preferredNetworks, _preferredNetworks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minSocPercent,maxSocPercent,const DeepCollectionEquality().hash(_preferredNetworks));

@override
String toString() {
  return 'ChargingPreferences(minSocPercent: $minSocPercent, maxSocPercent: $maxSocPercent, preferredNetworks: $preferredNetworks)';
}


}

/// @nodoc
abstract mixin class _$ChargingPreferencesCopyWith<$Res> implements $ChargingPreferencesCopyWith<$Res> {
  factory _$ChargingPreferencesCopyWith(_ChargingPreferences value, $Res Function(_ChargingPreferences) _then) = __$ChargingPreferencesCopyWithImpl;
@override @useResult
$Res call({
 int minSocPercent, int maxSocPercent, List<String> preferredNetworks
});




}
/// @nodoc
class __$ChargingPreferencesCopyWithImpl<$Res>
    implements _$ChargingPreferencesCopyWith<$Res> {
  __$ChargingPreferencesCopyWithImpl(this._self, this._then);

  final _ChargingPreferences _self;
  final $Res Function(_ChargingPreferences) _then;

/// Create a copy of ChargingPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minSocPercent = null,Object? maxSocPercent = null,Object? preferredNetworks = null,}) {
  return _then(_ChargingPreferences(
minSocPercent: null == minSocPercent ? _self.minSocPercent : minSocPercent // ignore: cast_nullable_to_non_nullable
as int,maxSocPercent: null == maxSocPercent ? _self.maxSocPercent : maxSocPercent // ignore: cast_nullable_to_non_nullable
as int,preferredNetworks: null == preferredNetworks ? _self._preferredNetworks : preferredNetworks // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$VehicleProfile {

 String get id; String get name;@VehicleTypeJsonConverter() VehicleType get type;// EV fields
 double? get batteryKwh; double? get maxChargingKw;@ConnectorTypeSetConverter() Set<ConnectorType> get supportedConnectors;@ChargingPreferencesJsonConverter() ChargingPreferences get chargingPreferences;// Combustion fields
 double? get tankCapacityL; String? get preferredFuelType;
/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleProfileCopyWith<VehicleProfile> get copyWith => _$VehicleProfileCopyWithImpl<VehicleProfile>(this as VehicleProfile, _$identity);

  /// Serializes this VehicleProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.batteryKwh, batteryKwh) || other.batteryKwh == batteryKwh)&&(identical(other.maxChargingKw, maxChargingKw) || other.maxChargingKw == maxChargingKw)&&const DeepCollectionEquality().equals(other.supportedConnectors, supportedConnectors)&&(identical(other.chargingPreferences, chargingPreferences) || other.chargingPreferences == chargingPreferences)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,batteryKwh,maxChargingKw,const DeepCollectionEquality().hash(supportedConnectors),chargingPreferences,tankCapacityL,preferredFuelType);

@override
String toString() {
  return 'VehicleProfile(id: $id, name: $name, type: $type, batteryKwh: $batteryKwh, maxChargingKw: $maxChargingKw, supportedConnectors: $supportedConnectors, chargingPreferences: $chargingPreferences, tankCapacityL: $tankCapacityL, preferredFuelType: $preferredFuelType)';
}


}

/// @nodoc
abstract mixin class $VehicleProfileCopyWith<$Res>  {
  factory $VehicleProfileCopyWith(VehicleProfile value, $Res Function(VehicleProfile) _then) = _$VehicleProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name,@VehicleTypeJsonConverter() VehicleType type, double? batteryKwh, double? maxChargingKw,@ConnectorTypeSetConverter() Set<ConnectorType> supportedConnectors,@ChargingPreferencesJsonConverter() ChargingPreferences chargingPreferences, double? tankCapacityL, String? preferredFuelType
});


$ChargingPreferencesCopyWith<$Res> get chargingPreferences;

}
/// @nodoc
class _$VehicleProfileCopyWithImpl<$Res>
    implements $VehicleProfileCopyWith<$Res> {
  _$VehicleProfileCopyWithImpl(this._self, this._then);

  final VehicleProfile _self;
  final $Res Function(VehicleProfile) _then;

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? batteryKwh = freezed,Object? maxChargingKw = freezed,Object? supportedConnectors = null,Object? chargingPreferences = null,Object? tankCapacityL = freezed,Object? preferredFuelType = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType,batteryKwh: freezed == batteryKwh ? _self.batteryKwh : batteryKwh // ignore: cast_nullable_to_non_nullable
as double?,maxChargingKw: freezed == maxChargingKw ? _self.maxChargingKw : maxChargingKw // ignore: cast_nullable_to_non_nullable
as double?,supportedConnectors: null == supportedConnectors ? _self.supportedConnectors : supportedConnectors // ignore: cast_nullable_to_non_nullable
as Set<ConnectorType>,chargingPreferences: null == chargingPreferences ? _self.chargingPreferences : chargingPreferences // ignore: cast_nullable_to_non_nullable
as ChargingPreferences,tankCapacityL: freezed == tankCapacityL ? _self.tankCapacityL : tankCapacityL // ignore: cast_nullable_to_non_nullable
as double?,preferredFuelType: freezed == preferredFuelType ? _self.preferredFuelType : preferredFuelType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChargingPreferencesCopyWith<$Res> get chargingPreferences {
  
  return $ChargingPreferencesCopyWith<$Res>(_self.chargingPreferences, (value) {
    return _then(_self.copyWith(chargingPreferences: value));
  });
}
}


/// Adds pattern-matching-related methods to [VehicleProfile].
extension VehicleProfilePatterns on VehicleProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleProfile value)  $default,){
final _that = this;
switch (_that) {
case _VehicleProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleProfile value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType)  $default,) {final _that = this;
switch (_that) {
case _VehicleProfile():
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @VehicleTypeJsonConverter()  VehicleType type,  double? batteryKwh,  double? maxChargingKw, @ConnectorTypeSetConverter()  Set<ConnectorType> supportedConnectors, @ChargingPreferencesJsonConverter()  ChargingPreferences chargingPreferences,  double? tankCapacityL,  String? preferredFuelType)?  $default,) {final _that = this;
switch (_that) {
case _VehicleProfile() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.batteryKwh,_that.maxChargingKw,_that.supportedConnectors,_that.chargingPreferences,_that.tankCapacityL,_that.preferredFuelType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleProfile extends VehicleProfile {
  const _VehicleProfile({required this.id, required this.name, @VehicleTypeJsonConverter() this.type = VehicleType.combustion, this.batteryKwh, this.maxChargingKw, @ConnectorTypeSetConverter() final  Set<ConnectorType> supportedConnectors = const <ConnectorType>{}, @ChargingPreferencesJsonConverter() this.chargingPreferences = const ChargingPreferences(), this.tankCapacityL, this.preferredFuelType}): _supportedConnectors = supportedConnectors,super._();
  factory _VehicleProfile.fromJson(Map<String, dynamic> json) => _$VehicleProfileFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey()@VehicleTypeJsonConverter() final  VehicleType type;
// EV fields
@override final  double? batteryKwh;
@override final  double? maxChargingKw;
 final  Set<ConnectorType> _supportedConnectors;
@override@JsonKey()@ConnectorTypeSetConverter() Set<ConnectorType> get supportedConnectors {
  if (_supportedConnectors is EqualUnmodifiableSetView) return _supportedConnectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_supportedConnectors);
}

@override@JsonKey()@ChargingPreferencesJsonConverter() final  ChargingPreferences chargingPreferences;
// Combustion fields
@override final  double? tankCapacityL;
@override final  String? preferredFuelType;

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleProfileCopyWith<_VehicleProfile> get copyWith => __$VehicleProfileCopyWithImpl<_VehicleProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.batteryKwh, batteryKwh) || other.batteryKwh == batteryKwh)&&(identical(other.maxChargingKw, maxChargingKw) || other.maxChargingKw == maxChargingKw)&&const DeepCollectionEquality().equals(other._supportedConnectors, _supportedConnectors)&&(identical(other.chargingPreferences, chargingPreferences) || other.chargingPreferences == chargingPreferences)&&(identical(other.tankCapacityL, tankCapacityL) || other.tankCapacityL == tankCapacityL)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,batteryKwh,maxChargingKw,const DeepCollectionEquality().hash(_supportedConnectors),chargingPreferences,tankCapacityL,preferredFuelType);

@override
String toString() {
  return 'VehicleProfile(id: $id, name: $name, type: $type, batteryKwh: $batteryKwh, maxChargingKw: $maxChargingKw, supportedConnectors: $supportedConnectors, chargingPreferences: $chargingPreferences, tankCapacityL: $tankCapacityL, preferredFuelType: $preferredFuelType)';
}


}

/// @nodoc
abstract mixin class _$VehicleProfileCopyWith<$Res> implements $VehicleProfileCopyWith<$Res> {
  factory _$VehicleProfileCopyWith(_VehicleProfile value, $Res Function(_VehicleProfile) _then) = __$VehicleProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@VehicleTypeJsonConverter() VehicleType type, double? batteryKwh, double? maxChargingKw,@ConnectorTypeSetConverter() Set<ConnectorType> supportedConnectors,@ChargingPreferencesJsonConverter() ChargingPreferences chargingPreferences, double? tankCapacityL, String? preferredFuelType
});


@override $ChargingPreferencesCopyWith<$Res> get chargingPreferences;

}
/// @nodoc
class __$VehicleProfileCopyWithImpl<$Res>
    implements _$VehicleProfileCopyWith<$Res> {
  __$VehicleProfileCopyWithImpl(this._self, this._then);

  final _VehicleProfile _self;
  final $Res Function(_VehicleProfile) _then;

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? batteryKwh = freezed,Object? maxChargingKw = freezed,Object? supportedConnectors = null,Object? chargingPreferences = null,Object? tankCapacityL = freezed,Object? preferredFuelType = freezed,}) {
  return _then(_VehicleProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as VehicleType,batteryKwh: freezed == batteryKwh ? _self.batteryKwh : batteryKwh // ignore: cast_nullable_to_non_nullable
as double?,maxChargingKw: freezed == maxChargingKw ? _self.maxChargingKw : maxChargingKw // ignore: cast_nullable_to_non_nullable
as double?,supportedConnectors: null == supportedConnectors ? _self._supportedConnectors : supportedConnectors // ignore: cast_nullable_to_non_nullable
as Set<ConnectorType>,chargingPreferences: null == chargingPreferences ? _self.chargingPreferences : chargingPreferences // ignore: cast_nullable_to_non_nullable
as ChargingPreferences,tankCapacityL: freezed == tankCapacityL ? _self.tankCapacityL : tankCapacityL // ignore: cast_nullable_to_non_nullable
as double?,preferredFuelType: freezed == preferredFuelType ? _self.preferredFuelType : preferredFuelType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of VehicleProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChargingPreferencesCopyWith<$Res> get chargingPreferences {
  
  return $ChargingPreferencesCopyWith<$Res>(_self.chargingPreferences, (value) {
    return _then(_self.copyWith(chargingPreferences: value));
  });
}
}

// dart format on
