// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 String get id; String get name; FuelType get preferredFuelType; double get defaultSearchRadius; LandingScreen get landingScreen; List<String> get favoriteStationIds; String? get homeZipCode; bool get autoUpdatePosition; String? get countryCode; String? get languageCode; double get routeSegmentKm; bool get avoidHighways; bool get showFuel; bool get showElectric;/// Rating sharing mode:
/// - 'local' — ratings saved only on this device
/// - 'private' — synced with user's database but not shared
/// - 'shared' — visible to all users of the database
 String get ratingMode;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType)&&(identical(other.defaultSearchRadius, defaultSearchRadius) || other.defaultSearchRadius == defaultSearchRadius)&&(identical(other.landingScreen, landingScreen) || other.landingScreen == landingScreen)&&const DeepCollectionEquality().equals(other.favoriteStationIds, favoriteStationIds)&&(identical(other.homeZipCode, homeZipCode) || other.homeZipCode == homeZipCode)&&(identical(other.autoUpdatePosition, autoUpdatePosition) || other.autoUpdatePosition == autoUpdatePosition)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.routeSegmentKm, routeSegmentKm) || other.routeSegmentKm == routeSegmentKm)&&(identical(other.avoidHighways, avoidHighways) || other.avoidHighways == avoidHighways)&&(identical(other.showFuel, showFuel) || other.showFuel == showFuel)&&(identical(other.showElectric, showElectric) || other.showElectric == showElectric)&&(identical(other.ratingMode, ratingMode) || other.ratingMode == ratingMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,preferredFuelType,defaultSearchRadius,landingScreen,const DeepCollectionEquality().hash(favoriteStationIds),homeZipCode,autoUpdatePosition,countryCode,languageCode,routeSegmentKm,avoidHighways,showFuel,showElectric,ratingMode);

@override
String toString() {
  return 'UserProfile(id: $id, name: $name, preferredFuelType: $preferredFuelType, defaultSearchRadius: $defaultSearchRadius, landingScreen: $landingScreen, favoriteStationIds: $favoriteStationIds, homeZipCode: $homeZipCode, autoUpdatePosition: $autoUpdatePosition, countryCode: $countryCode, languageCode: $languageCode, routeSegmentKm: $routeSegmentKm, avoidHighways: $avoidHighways, showFuel: $showFuel, showElectric: $showElectric, ratingMode: $ratingMode)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name, FuelType preferredFuelType, double defaultSearchRadius, LandingScreen landingScreen, List<String> favoriteStationIds, String? homeZipCode, bool autoUpdatePosition, String? countryCode, String? languageCode, double routeSegmentKm, bool avoidHighways, bool showFuel, bool showElectric, String ratingMode
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? preferredFuelType = null,Object? defaultSearchRadius = null,Object? landingScreen = null,Object? favoriteStationIds = null,Object? homeZipCode = freezed,Object? autoUpdatePosition = null,Object? countryCode = freezed,Object? languageCode = freezed,Object? routeSegmentKm = null,Object? avoidHighways = null,Object? showFuel = null,Object? showElectric = null,Object? ratingMode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,preferredFuelType: null == preferredFuelType ? _self.preferredFuelType : preferredFuelType // ignore: cast_nullable_to_non_nullable
as FuelType,defaultSearchRadius: null == defaultSearchRadius ? _self.defaultSearchRadius : defaultSearchRadius // ignore: cast_nullable_to_non_nullable
as double,landingScreen: null == landingScreen ? _self.landingScreen : landingScreen // ignore: cast_nullable_to_non_nullable
as LandingScreen,favoriteStationIds: null == favoriteStationIds ? _self.favoriteStationIds : favoriteStationIds // ignore: cast_nullable_to_non_nullable
as List<String>,homeZipCode: freezed == homeZipCode ? _self.homeZipCode : homeZipCode // ignore: cast_nullable_to_non_nullable
as String?,autoUpdatePosition: null == autoUpdatePosition ? _self.autoUpdatePosition : autoUpdatePosition // ignore: cast_nullable_to_non_nullable
as bool,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,languageCode: freezed == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String?,routeSegmentKm: null == routeSegmentKm ? _self.routeSegmentKm : routeSegmentKm // ignore: cast_nullable_to_non_nullable
as double,avoidHighways: null == avoidHighways ? _self.avoidHighways : avoidHighways // ignore: cast_nullable_to_non_nullable
as bool,showFuel: null == showFuel ? _self.showFuel : showFuel // ignore: cast_nullable_to_non_nullable
as bool,showElectric: null == showElectric ? _self.showElectric : showElectric // ignore: cast_nullable_to_non_nullable
as bool,ratingMode: null == ratingMode ? _self.ratingMode : ratingMode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  FuelType preferredFuelType,  double defaultSearchRadius,  LandingScreen landingScreen,  List<String> favoriteStationIds,  String? homeZipCode,  bool autoUpdatePosition,  String? countryCode,  String? languageCode,  double routeSegmentKm,  bool avoidHighways,  bool showFuel,  bool showElectric,  String ratingMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.name,_that.preferredFuelType,_that.defaultSearchRadius,_that.landingScreen,_that.favoriteStationIds,_that.homeZipCode,_that.autoUpdatePosition,_that.countryCode,_that.languageCode,_that.routeSegmentKm,_that.avoidHighways,_that.showFuel,_that.showElectric,_that.ratingMode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  FuelType preferredFuelType,  double defaultSearchRadius,  LandingScreen landingScreen,  List<String> favoriteStationIds,  String? homeZipCode,  bool autoUpdatePosition,  String? countryCode,  String? languageCode,  double routeSegmentKm,  bool avoidHighways,  bool showFuel,  bool showElectric,  String ratingMode)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.name,_that.preferredFuelType,_that.defaultSearchRadius,_that.landingScreen,_that.favoriteStationIds,_that.homeZipCode,_that.autoUpdatePosition,_that.countryCode,_that.languageCode,_that.routeSegmentKm,_that.avoidHighways,_that.showFuel,_that.showElectric,_that.ratingMode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  FuelType preferredFuelType,  double defaultSearchRadius,  LandingScreen landingScreen,  List<String> favoriteStationIds,  String? homeZipCode,  bool autoUpdatePosition,  String? countryCode,  String? languageCode,  double routeSegmentKm,  bool avoidHighways,  bool showFuel,  bool showElectric,  String ratingMode)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.name,_that.preferredFuelType,_that.defaultSearchRadius,_that.landingScreen,_that.favoriteStationIds,_that.homeZipCode,_that.autoUpdatePosition,_that.countryCode,_that.languageCode,_that.routeSegmentKm,_that.avoidHighways,_that.showFuel,_that.showElectric,_that.ratingMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile implements UserProfile {
  const _UserProfile({required this.id, required this.name, this.preferredFuelType = FuelType.e10, this.defaultSearchRadius = 10.0, this.landingScreen = LandingScreen.search, final  List<String> favoriteStationIds = const [], this.homeZipCode, this.autoUpdatePosition = false, this.countryCode, this.languageCode, this.routeSegmentKm = 50.0, this.avoidHighways = false, this.showFuel = true, this.showElectric = true, this.ratingMode = 'local'}): _favoriteStationIds = favoriteStationIds;
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  FuelType preferredFuelType;
@override@JsonKey() final  double defaultSearchRadius;
@override@JsonKey() final  LandingScreen landingScreen;
 final  List<String> _favoriteStationIds;
@override@JsonKey() List<String> get favoriteStationIds {
  if (_favoriteStationIds is EqualUnmodifiableListView) return _favoriteStationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favoriteStationIds);
}

@override final  String? homeZipCode;
@override@JsonKey() final  bool autoUpdatePosition;
@override final  String? countryCode;
@override final  String? languageCode;
@override@JsonKey() final  double routeSegmentKm;
@override@JsonKey() final  bool avoidHighways;
@override@JsonKey() final  bool showFuel;
@override@JsonKey() final  bool showElectric;
/// Rating sharing mode:
/// - 'local' — ratings saved only on this device
/// - 'private' — synced with user's database but not shared
/// - 'shared' — visible to all users of the database
@override@JsonKey() final  String ratingMode;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType)&&(identical(other.defaultSearchRadius, defaultSearchRadius) || other.defaultSearchRadius == defaultSearchRadius)&&(identical(other.landingScreen, landingScreen) || other.landingScreen == landingScreen)&&const DeepCollectionEquality().equals(other._favoriteStationIds, _favoriteStationIds)&&(identical(other.homeZipCode, homeZipCode) || other.homeZipCode == homeZipCode)&&(identical(other.autoUpdatePosition, autoUpdatePosition) || other.autoUpdatePosition == autoUpdatePosition)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.routeSegmentKm, routeSegmentKm) || other.routeSegmentKm == routeSegmentKm)&&(identical(other.avoidHighways, avoidHighways) || other.avoidHighways == avoidHighways)&&(identical(other.showFuel, showFuel) || other.showFuel == showFuel)&&(identical(other.showElectric, showElectric) || other.showElectric == showElectric)&&(identical(other.ratingMode, ratingMode) || other.ratingMode == ratingMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,preferredFuelType,defaultSearchRadius,landingScreen,const DeepCollectionEquality().hash(_favoriteStationIds),homeZipCode,autoUpdatePosition,countryCode,languageCode,routeSegmentKm,avoidHighways,showFuel,showElectric,ratingMode);

@override
String toString() {
  return 'UserProfile(id: $id, name: $name, preferredFuelType: $preferredFuelType, defaultSearchRadius: $defaultSearchRadius, landingScreen: $landingScreen, favoriteStationIds: $favoriteStationIds, homeZipCode: $homeZipCode, autoUpdatePosition: $autoUpdatePosition, countryCode: $countryCode, languageCode: $languageCode, routeSegmentKm: $routeSegmentKm, avoidHighways: $avoidHighways, showFuel: $showFuel, showElectric: $showElectric, ratingMode: $ratingMode)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, FuelType preferredFuelType, double defaultSearchRadius, LandingScreen landingScreen, List<String> favoriteStationIds, String? homeZipCode, bool autoUpdatePosition, String? countryCode, String? languageCode, double routeSegmentKm, bool avoidHighways, bool showFuel, bool showElectric, String ratingMode
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? preferredFuelType = null,Object? defaultSearchRadius = null,Object? landingScreen = null,Object? favoriteStationIds = null,Object? homeZipCode = freezed,Object? autoUpdatePosition = null,Object? countryCode = freezed,Object? languageCode = freezed,Object? routeSegmentKm = null,Object? avoidHighways = null,Object? showFuel = null,Object? showElectric = null,Object? ratingMode = null,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,preferredFuelType: null == preferredFuelType ? _self.preferredFuelType : preferredFuelType // ignore: cast_nullable_to_non_nullable
as FuelType,defaultSearchRadius: null == defaultSearchRadius ? _self.defaultSearchRadius : defaultSearchRadius // ignore: cast_nullable_to_non_nullable
as double,landingScreen: null == landingScreen ? _self.landingScreen : landingScreen // ignore: cast_nullable_to_non_nullable
as LandingScreen,favoriteStationIds: null == favoriteStationIds ? _self._favoriteStationIds : favoriteStationIds // ignore: cast_nullable_to_non_nullable
as List<String>,homeZipCode: freezed == homeZipCode ? _self.homeZipCode : homeZipCode // ignore: cast_nullable_to_non_nullable
as String?,autoUpdatePosition: null == autoUpdatePosition ? _self.autoUpdatePosition : autoUpdatePosition // ignore: cast_nullable_to_non_nullable
as bool,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,languageCode: freezed == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String?,routeSegmentKm: null == routeSegmentKm ? _self.routeSegmentKm : routeSegmentKm // ignore: cast_nullable_to_non_nullable
as double,avoidHighways: null == avoidHighways ? _self.avoidHighways : avoidHighways // ignore: cast_nullable_to_non_nullable
as bool,showFuel: null == showFuel ? _self.showFuel : showFuel // ignore: cast_nullable_to_non_nullable
as bool,showElectric: null == showElectric ? _self.showElectric : showElectric // ignore: cast_nullable_to_non_nullable
as bool,ratingMode: null == ratingMode ? _self.ratingMode : ratingMode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
