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

 String get id; String get name;@FuelTypeJsonConverter() FuelType get preferredFuelType; double get defaultSearchRadius; LandingScreen get landingScreen; List<String> get favoriteStationIds; String? get homeZipCode; bool get autoUpdatePosition; String? get countryCode; String? get languageCode; double get routeSegmentKm; bool get avoidHighways;/// Maximum detour (km) the user is willing to deviate from the
/// direct route when route-planning surfaces off-corridor stations
/// (#1602). Feeds `RouteSearchState.searchAlongRoute`'s
/// `searchRadiusKm` / `maxDetourKm`. The 5.0 km default matches the
/// prior hard-coded call-site default, so existing profiles see no
/// behaviour change.
 double get routeDetourBudgetKm;/// Minimum price advantage (€/L) a route-planning station must have
/// over the cheapest station found along the route to stay in the
/// result feed (#1872). `0.0` disables the filter — every station
/// along the route is shown (the default, behaviour-preserving).
/// A positive value keeps only stations priced within this band of
/// the route's cheapest, decluttering the feed to genuinely
/// competitive stops.
 double get minRouteSavingPerLiter;@Deprecated('Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.') bool get showFuel;@Deprecated('Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.') bool get showElectric;/// Rating sharing mode:
/// - 'local' — ratings saved only on this device
/// - 'private' — synced with user's database but not shared
/// - 'shared' — visible to all users of the database
 String get ratingMode;/// Amenities the user requires at stations by default (empty = no filter).
/// Persisted per-profile and loaded into the search criteria screen.
 List<StationAmenity> get preferredAmenities;/// Optional reference to the user's default [VehicleProfile] (#694).
/// When set, AddFillUpScreen pre-selects this vehicle. Null keeps the
/// vehicle selector empty so the user can still log fill-ups without
/// attributing them to any vehicle.
 String? get defaultVehicleId;/// Tie-breaker for hybrid default vehicles (#706). Null on
/// non-hybrid vehicles. When set to [FuelType.electric], search
/// + station filters treat a hybrid like an EV; when set to any
/// combustion fuel, they treat it like a petrol/diesel car.
/// Defaults to null so existing profiles don't need migration.
@FuelTypeJsonConverter() FuelType? get hybridFuelChoice;/// Opt-in visibility of the Consumption tab in the bottom nav
/// (#701). The tab stays hidden unless this is true AND at least
/// one vehicle is configured — the log is vehicle-centric and a
/// first-time user without a vehicle would only see the empty
/// state.
@Deprecated('Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.') bool get showConsumptionTab;/// Master toggle for gamification surfaces (#1194). Defaults to
/// true so existing users see no behaviour change. When flipped
/// off, badges, scores, achievement tabs, and trophy iconography
/// are hidden across the app — the underlying achievement
/// evaluation continues to run so toggling back on instantly
/// restores any earned badges.
@Deprecated('Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.') bool get gamificationEnabled;/// Radius (in km) within which the in-trip approach overlay
/// (#2067 / Epic #2065) grows + flips to a huge price figure for
/// the user's fuel type. Range 0.5–5.0 in 0.5 km steps; default
/// 1.0 km. In countries that use miles (UK/US), the slider label
/// is rendered via `UnitFormatter`; the persisted value stays km.
 double get approachRadiusKm;/// Which station price the approach overlay shows when the driver
/// is inside [approachRadiusKm]: the nearest station the radius
/// was crossed for, or the cheapest station currently in range.
/// See [ApproachPriceMode].
 ApproachPriceMode get approachPriceMode;/// Floor on how often the approach detector polls the search
/// chain while a trajet is recording (#2067 / Epic #2065). The
/// actual cadence is speed-adaptive (≈ 20 % of `radius_m / speed`)
/// but is never tighter than this floor — protects the search
/// provider quota. Range 1–10 s; default 5 s.
 int get approachMinPollSeconds;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType)&&(identical(other.defaultSearchRadius, defaultSearchRadius) || other.defaultSearchRadius == defaultSearchRadius)&&(identical(other.landingScreen, landingScreen) || other.landingScreen == landingScreen)&&const DeepCollectionEquality().equals(other.favoriteStationIds, favoriteStationIds)&&(identical(other.homeZipCode, homeZipCode) || other.homeZipCode == homeZipCode)&&(identical(other.autoUpdatePosition, autoUpdatePosition) || other.autoUpdatePosition == autoUpdatePosition)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.routeSegmentKm, routeSegmentKm) || other.routeSegmentKm == routeSegmentKm)&&(identical(other.avoidHighways, avoidHighways) || other.avoidHighways == avoidHighways)&&(identical(other.routeDetourBudgetKm, routeDetourBudgetKm) || other.routeDetourBudgetKm == routeDetourBudgetKm)&&(identical(other.minRouteSavingPerLiter, minRouteSavingPerLiter) || other.minRouteSavingPerLiter == minRouteSavingPerLiter)&&(identical(other.showFuel, showFuel) || other.showFuel == showFuel)&&(identical(other.showElectric, showElectric) || other.showElectric == showElectric)&&(identical(other.ratingMode, ratingMode) || other.ratingMode == ratingMode)&&const DeepCollectionEquality().equals(other.preferredAmenities, preferredAmenities)&&(identical(other.defaultVehicleId, defaultVehicleId) || other.defaultVehicleId == defaultVehicleId)&&(identical(other.hybridFuelChoice, hybridFuelChoice) || other.hybridFuelChoice == hybridFuelChoice)&&(identical(other.showConsumptionTab, showConsumptionTab) || other.showConsumptionTab == showConsumptionTab)&&(identical(other.gamificationEnabled, gamificationEnabled) || other.gamificationEnabled == gamificationEnabled)&&(identical(other.approachRadiusKm, approachRadiusKm) || other.approachRadiusKm == approachRadiusKm)&&(identical(other.approachPriceMode, approachPriceMode) || other.approachPriceMode == approachPriceMode)&&(identical(other.approachMinPollSeconds, approachMinPollSeconds) || other.approachMinPollSeconds == approachMinPollSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,preferredFuelType,defaultSearchRadius,landingScreen,const DeepCollectionEquality().hash(favoriteStationIds),homeZipCode,autoUpdatePosition,countryCode,languageCode,routeSegmentKm,avoidHighways,routeDetourBudgetKm,minRouteSavingPerLiter,showFuel,showElectric,ratingMode,const DeepCollectionEquality().hash(preferredAmenities),defaultVehicleId,hybridFuelChoice,showConsumptionTab,gamificationEnabled,approachRadiusKm,approachPriceMode,approachMinPollSeconds]);

@override
String toString() {
  return 'UserProfile(id: $id, name: $name, preferredFuelType: $preferredFuelType, defaultSearchRadius: $defaultSearchRadius, landingScreen: $landingScreen, favoriteStationIds: $favoriteStationIds, homeZipCode: $homeZipCode, autoUpdatePosition: $autoUpdatePosition, countryCode: $countryCode, languageCode: $languageCode, routeSegmentKm: $routeSegmentKm, avoidHighways: $avoidHighways, routeDetourBudgetKm: $routeDetourBudgetKm, minRouteSavingPerLiter: $minRouteSavingPerLiter, showFuel: $showFuel, showElectric: $showElectric, ratingMode: $ratingMode, preferredAmenities: $preferredAmenities, defaultVehicleId: $defaultVehicleId, hybridFuelChoice: $hybridFuelChoice, showConsumptionTab: $showConsumptionTab, gamificationEnabled: $gamificationEnabled, approachRadiusKm: $approachRadiusKm, approachPriceMode: $approachPriceMode, approachMinPollSeconds: $approachMinPollSeconds)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String id, String name,@FuelTypeJsonConverter() FuelType preferredFuelType, double defaultSearchRadius, LandingScreen landingScreen, List<String> favoriteStationIds, String? homeZipCode, bool autoUpdatePosition, String? countryCode, String? languageCode, double routeSegmentKm, bool avoidHighways, double routeDetourBudgetKm, double minRouteSavingPerLiter,@Deprecated('Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.') bool showFuel,@Deprecated('Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.') bool showElectric, String ratingMode, List<StationAmenity> preferredAmenities, String? defaultVehicleId,@FuelTypeJsonConverter() FuelType? hybridFuelChoice,@Deprecated('Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.') bool showConsumptionTab,@Deprecated('Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.') bool gamificationEnabled, double approachRadiusKm, ApproachPriceMode approachPriceMode, int approachMinPollSeconds
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? preferredFuelType = null,Object? defaultSearchRadius = null,Object? landingScreen = null,Object? favoriteStationIds = null,Object? homeZipCode = freezed,Object? autoUpdatePosition = null,Object? countryCode = freezed,Object? languageCode = freezed,Object? routeSegmentKm = null,Object? avoidHighways = null,Object? routeDetourBudgetKm = null,Object? minRouteSavingPerLiter = null,Object? showFuel = null,Object? showElectric = null,Object? ratingMode = null,Object? preferredAmenities = null,Object? defaultVehicleId = freezed,Object? hybridFuelChoice = freezed,Object? showConsumptionTab = null,Object? gamificationEnabled = null,Object? approachRadiusKm = null,Object? approachPriceMode = null,Object? approachMinPollSeconds = null,}) {
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
as bool,routeDetourBudgetKm: null == routeDetourBudgetKm ? _self.routeDetourBudgetKm : routeDetourBudgetKm // ignore: cast_nullable_to_non_nullable
as double,minRouteSavingPerLiter: null == minRouteSavingPerLiter ? _self.minRouteSavingPerLiter : minRouteSavingPerLiter // ignore: cast_nullable_to_non_nullable
as double,showFuel: null == showFuel ? _self.showFuel : showFuel // ignore: cast_nullable_to_non_nullable
as bool,showElectric: null == showElectric ? _self.showElectric : showElectric // ignore: cast_nullable_to_non_nullable
as bool,ratingMode: null == ratingMode ? _self.ratingMode : ratingMode // ignore: cast_nullable_to_non_nullable
as String,preferredAmenities: null == preferredAmenities ? _self.preferredAmenities : preferredAmenities // ignore: cast_nullable_to_non_nullable
as List<StationAmenity>,defaultVehicleId: freezed == defaultVehicleId ? _self.defaultVehicleId : defaultVehicleId // ignore: cast_nullable_to_non_nullable
as String?,hybridFuelChoice: freezed == hybridFuelChoice ? _self.hybridFuelChoice : hybridFuelChoice // ignore: cast_nullable_to_non_nullable
as FuelType?,showConsumptionTab: null == showConsumptionTab ? _self.showConsumptionTab : showConsumptionTab // ignore: cast_nullable_to_non_nullable
as bool,gamificationEnabled: null == gamificationEnabled ? _self.gamificationEnabled : gamificationEnabled // ignore: cast_nullable_to_non_nullable
as bool,approachRadiusKm: null == approachRadiusKm ? _self.approachRadiusKm : approachRadiusKm // ignore: cast_nullable_to_non_nullable
as double,approachPriceMode: null == approachPriceMode ? _self.approachPriceMode : approachPriceMode // ignore: cast_nullable_to_non_nullable
as ApproachPriceMode,approachMinPollSeconds: null == approachMinPollSeconds ? _self.approachMinPollSeconds : approachMinPollSeconds // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @FuelTypeJsonConverter()  FuelType preferredFuelType,  double defaultSearchRadius,  LandingScreen landingScreen,  List<String> favoriteStationIds,  String? homeZipCode,  bool autoUpdatePosition,  String? countryCode,  String? languageCode,  double routeSegmentKm,  bool avoidHighways,  double routeDetourBudgetKm,  double minRouteSavingPerLiter, @Deprecated('Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.')  bool showFuel, @Deprecated('Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.')  bool showElectric,  String ratingMode,  List<StationAmenity> preferredAmenities,  String? defaultVehicleId, @FuelTypeJsonConverter()  FuelType? hybridFuelChoice, @Deprecated('Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.')  bool showConsumptionTab, @Deprecated('Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.')  bool gamificationEnabled,  double approachRadiusKm,  ApproachPriceMode approachPriceMode,  int approachMinPollSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.name,_that.preferredFuelType,_that.defaultSearchRadius,_that.landingScreen,_that.favoriteStationIds,_that.homeZipCode,_that.autoUpdatePosition,_that.countryCode,_that.languageCode,_that.routeSegmentKm,_that.avoidHighways,_that.routeDetourBudgetKm,_that.minRouteSavingPerLiter,_that.showFuel,_that.showElectric,_that.ratingMode,_that.preferredAmenities,_that.defaultVehicleId,_that.hybridFuelChoice,_that.showConsumptionTab,_that.gamificationEnabled,_that.approachRadiusKm,_that.approachPriceMode,_that.approachMinPollSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @FuelTypeJsonConverter()  FuelType preferredFuelType,  double defaultSearchRadius,  LandingScreen landingScreen,  List<String> favoriteStationIds,  String? homeZipCode,  bool autoUpdatePosition,  String? countryCode,  String? languageCode,  double routeSegmentKm,  bool avoidHighways,  double routeDetourBudgetKm,  double minRouteSavingPerLiter, @Deprecated('Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.')  bool showFuel, @Deprecated('Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.')  bool showElectric,  String ratingMode,  List<StationAmenity> preferredAmenities,  String? defaultVehicleId, @FuelTypeJsonConverter()  FuelType? hybridFuelChoice, @Deprecated('Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.')  bool showConsumptionTab, @Deprecated('Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.')  bool gamificationEnabled,  double approachRadiusKm,  ApproachPriceMode approachPriceMode,  int approachMinPollSeconds)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.name,_that.preferredFuelType,_that.defaultSearchRadius,_that.landingScreen,_that.favoriteStationIds,_that.homeZipCode,_that.autoUpdatePosition,_that.countryCode,_that.languageCode,_that.routeSegmentKm,_that.avoidHighways,_that.routeDetourBudgetKm,_that.minRouteSavingPerLiter,_that.showFuel,_that.showElectric,_that.ratingMode,_that.preferredAmenities,_that.defaultVehicleId,_that.hybridFuelChoice,_that.showConsumptionTab,_that.gamificationEnabled,_that.approachRadiusKm,_that.approachPriceMode,_that.approachMinPollSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @FuelTypeJsonConverter()  FuelType preferredFuelType,  double defaultSearchRadius,  LandingScreen landingScreen,  List<String> favoriteStationIds,  String? homeZipCode,  bool autoUpdatePosition,  String? countryCode,  String? languageCode,  double routeSegmentKm,  bool avoidHighways,  double routeDetourBudgetKm,  double minRouteSavingPerLiter, @Deprecated('Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.')  bool showFuel, @Deprecated('Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.')  bool showElectric,  String ratingMode,  List<StationAmenity> preferredAmenities,  String? defaultVehicleId, @FuelTypeJsonConverter()  FuelType? hybridFuelChoice, @Deprecated('Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.')  bool showConsumptionTab, @Deprecated('Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.')  bool gamificationEnabled,  double approachRadiusKm,  ApproachPriceMode approachPriceMode,  int approachMinPollSeconds)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.name,_that.preferredFuelType,_that.defaultSearchRadius,_that.landingScreen,_that.favoriteStationIds,_that.homeZipCode,_that.autoUpdatePosition,_that.countryCode,_that.languageCode,_that.routeSegmentKm,_that.avoidHighways,_that.routeDetourBudgetKm,_that.minRouteSavingPerLiter,_that.showFuel,_that.showElectric,_that.ratingMode,_that.preferredAmenities,_that.defaultVehicleId,_that.hybridFuelChoice,_that.showConsumptionTab,_that.gamificationEnabled,_that.approachRadiusKm,_that.approachPriceMode,_that.approachMinPollSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile implements UserProfile {
  const _UserProfile({required this.id, required this.name, @FuelTypeJsonConverter() this.preferredFuelType = FuelType.e10, this.defaultSearchRadius = 10.0, this.landingScreen = LandingScreen.nearest, final  List<String> favoriteStationIds = const [], this.homeZipCode, this.autoUpdatePosition = false, this.countryCode, this.languageCode, this.routeSegmentKm = 50.0, this.avoidHighways = false, this.routeDetourBudgetKm = 5.0, this.minRouteSavingPerLiter = 0.0, @Deprecated('Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.') this.showFuel = true, @Deprecated('Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.') this.showElectric = true, this.ratingMode = 'local', final  List<StationAmenity> preferredAmenities = const [], this.defaultVehicleId, @FuelTypeJsonConverter() this.hybridFuelChoice, @Deprecated('Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.') this.showConsumptionTab = false, @Deprecated('Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.') this.gamificationEnabled = true, this.approachRadiusKm = 1.0, this.approachPriceMode = ApproachPriceMode.nearest, this.approachMinPollSeconds = 5}): _favoriteStationIds = favoriteStationIds,_preferredAmenities = preferredAmenities;
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey()@FuelTypeJsonConverter() final  FuelType preferredFuelType;
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
/// Maximum detour (km) the user is willing to deviate from the
/// direct route when route-planning surfaces off-corridor stations
/// (#1602). Feeds `RouteSearchState.searchAlongRoute`'s
/// `searchRadiusKm` / `maxDetourKm`. The 5.0 km default matches the
/// prior hard-coded call-site default, so existing profiles see no
/// behaviour change.
@override@JsonKey() final  double routeDetourBudgetKm;
/// Minimum price advantage (€/L) a route-planning station must have
/// over the cheapest station found along the route to stay in the
/// result feed (#1872). `0.0` disables the filter — every station
/// along the route is shown (the default, behaviour-preserving).
/// A positive value keeps only stations priced within this band of
/// the route's cheapest, decluttering the feed to genuinely
/// competitive stops.
@override@JsonKey() final  double minRouteSavingPerLiter;
@override@JsonKey()@Deprecated('Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.') final  bool showFuel;
@override@JsonKey()@Deprecated('Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.') final  bool showElectric;
/// Rating sharing mode:
/// - 'local' — ratings saved only on this device
/// - 'private' — synced with user's database but not shared
/// - 'shared' — visible to all users of the database
@override@JsonKey() final  String ratingMode;
/// Amenities the user requires at stations by default (empty = no filter).
/// Persisted per-profile and loaded into the search criteria screen.
 final  List<StationAmenity> _preferredAmenities;
/// Amenities the user requires at stations by default (empty = no filter).
/// Persisted per-profile and loaded into the search criteria screen.
@override@JsonKey() List<StationAmenity> get preferredAmenities {
  if (_preferredAmenities is EqualUnmodifiableListView) return _preferredAmenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preferredAmenities);
}

/// Optional reference to the user's default [VehicleProfile] (#694).
/// When set, AddFillUpScreen pre-selects this vehicle. Null keeps the
/// vehicle selector empty so the user can still log fill-ups without
/// attributing them to any vehicle.
@override final  String? defaultVehicleId;
/// Tie-breaker for hybrid default vehicles (#706). Null on
/// non-hybrid vehicles. When set to [FuelType.electric], search
/// + station filters treat a hybrid like an EV; when set to any
/// combustion fuel, they treat it like a petrol/diesel car.
/// Defaults to null so existing profiles don't need migration.
@override@FuelTypeJsonConverter() final  FuelType? hybridFuelChoice;
/// Opt-in visibility of the Consumption tab in the bottom nav
/// (#701). The tab stays hidden unless this is true AND at least
/// one vehicle is configured — the log is vehicle-centric and a
/// first-time user without a vehicle would only see the empty
/// state.
@override@JsonKey()@Deprecated('Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.') final  bool showConsumptionTab;
/// Master toggle for gamification surfaces (#1194). Defaults to
/// true so existing users see no behaviour change. When flipped
/// off, badges, scores, achievement tabs, and trophy iconography
/// are hidden across the app — the underlying achievement
/// evaluation continues to run so toggling back on instantly
/// restores any earned badges.
@override@JsonKey()@Deprecated('Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.') final  bool gamificationEnabled;
/// Radius (in km) within which the in-trip approach overlay
/// (#2067 / Epic #2065) grows + flips to a huge price figure for
/// the user's fuel type. Range 0.5–5.0 in 0.5 km steps; default
/// 1.0 km. In countries that use miles (UK/US), the slider label
/// is rendered via `UnitFormatter`; the persisted value stays km.
@override@JsonKey() final  double approachRadiusKm;
/// Which station price the approach overlay shows when the driver
/// is inside [approachRadiusKm]: the nearest station the radius
/// was crossed for, or the cheapest station currently in range.
/// See [ApproachPriceMode].
@override@JsonKey() final  ApproachPriceMode approachPriceMode;
/// Floor on how often the approach detector polls the search
/// chain while a trajet is recording (#2067 / Epic #2065). The
/// actual cadence is speed-adaptive (≈ 20 % of `radius_m / speed`)
/// but is never tighter than this floor — protects the search
/// provider quota. Range 1–10 s; default 5 s.
@override@JsonKey() final  int approachMinPollSeconds;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.preferredFuelType, preferredFuelType) || other.preferredFuelType == preferredFuelType)&&(identical(other.defaultSearchRadius, defaultSearchRadius) || other.defaultSearchRadius == defaultSearchRadius)&&(identical(other.landingScreen, landingScreen) || other.landingScreen == landingScreen)&&const DeepCollectionEquality().equals(other._favoriteStationIds, _favoriteStationIds)&&(identical(other.homeZipCode, homeZipCode) || other.homeZipCode == homeZipCode)&&(identical(other.autoUpdatePosition, autoUpdatePosition) || other.autoUpdatePosition == autoUpdatePosition)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode)&&(identical(other.routeSegmentKm, routeSegmentKm) || other.routeSegmentKm == routeSegmentKm)&&(identical(other.avoidHighways, avoidHighways) || other.avoidHighways == avoidHighways)&&(identical(other.routeDetourBudgetKm, routeDetourBudgetKm) || other.routeDetourBudgetKm == routeDetourBudgetKm)&&(identical(other.minRouteSavingPerLiter, minRouteSavingPerLiter) || other.minRouteSavingPerLiter == minRouteSavingPerLiter)&&(identical(other.showFuel, showFuel) || other.showFuel == showFuel)&&(identical(other.showElectric, showElectric) || other.showElectric == showElectric)&&(identical(other.ratingMode, ratingMode) || other.ratingMode == ratingMode)&&const DeepCollectionEquality().equals(other._preferredAmenities, _preferredAmenities)&&(identical(other.defaultVehicleId, defaultVehicleId) || other.defaultVehicleId == defaultVehicleId)&&(identical(other.hybridFuelChoice, hybridFuelChoice) || other.hybridFuelChoice == hybridFuelChoice)&&(identical(other.showConsumptionTab, showConsumptionTab) || other.showConsumptionTab == showConsumptionTab)&&(identical(other.gamificationEnabled, gamificationEnabled) || other.gamificationEnabled == gamificationEnabled)&&(identical(other.approachRadiusKm, approachRadiusKm) || other.approachRadiusKm == approachRadiusKm)&&(identical(other.approachPriceMode, approachPriceMode) || other.approachPriceMode == approachPriceMode)&&(identical(other.approachMinPollSeconds, approachMinPollSeconds) || other.approachMinPollSeconds == approachMinPollSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,preferredFuelType,defaultSearchRadius,landingScreen,const DeepCollectionEquality().hash(_favoriteStationIds),homeZipCode,autoUpdatePosition,countryCode,languageCode,routeSegmentKm,avoidHighways,routeDetourBudgetKm,minRouteSavingPerLiter,showFuel,showElectric,ratingMode,const DeepCollectionEquality().hash(_preferredAmenities),defaultVehicleId,hybridFuelChoice,showConsumptionTab,gamificationEnabled,approachRadiusKm,approachPriceMode,approachMinPollSeconds]);

@override
String toString() {
  return 'UserProfile(id: $id, name: $name, preferredFuelType: $preferredFuelType, defaultSearchRadius: $defaultSearchRadius, landingScreen: $landingScreen, favoriteStationIds: $favoriteStationIds, homeZipCode: $homeZipCode, autoUpdatePosition: $autoUpdatePosition, countryCode: $countryCode, languageCode: $languageCode, routeSegmentKm: $routeSegmentKm, avoidHighways: $avoidHighways, routeDetourBudgetKm: $routeDetourBudgetKm, minRouteSavingPerLiter: $minRouteSavingPerLiter, showFuel: $showFuel, showElectric: $showElectric, ratingMode: $ratingMode, preferredAmenities: $preferredAmenities, defaultVehicleId: $defaultVehicleId, hybridFuelChoice: $hybridFuelChoice, showConsumptionTab: $showConsumptionTab, gamificationEnabled: $gamificationEnabled, approachRadiusKm: $approachRadiusKm, approachPriceMode: $approachPriceMode, approachMinPollSeconds: $approachMinPollSeconds)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@FuelTypeJsonConverter() FuelType preferredFuelType, double defaultSearchRadius, LandingScreen landingScreen, List<String> favoriteStationIds, String? homeZipCode, bool autoUpdatePosition, String? countryCode, String? languageCode, double routeSegmentKm, bool avoidHighways, double routeDetourBudgetKm, double minRouteSavingPerLiter,@Deprecated('Migrated to Feature.showFuel in #1373 phase 3c; kept for one-shot migration read.') bool showFuel,@Deprecated('Migrated to Feature.showElectric in #1373 phase 3c; kept for one-shot migration read.') bool showElectric, String ratingMode, List<StationAmenity> preferredAmenities, String? defaultVehicleId,@FuelTypeJsonConverter() FuelType? hybridFuelChoice,@Deprecated('Migrated to Feature.showConsumptionTab in #1373 phase 3c; kept for one-shot migration read.') bool showConsumptionTab,@Deprecated('Migrated to Feature.gamification in #1373 phase 3b; kept for one-shot migration read.') bool gamificationEnabled, double approachRadiusKm, ApproachPriceMode approachPriceMode, int approachMinPollSeconds
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? preferredFuelType = null,Object? defaultSearchRadius = null,Object? landingScreen = null,Object? favoriteStationIds = null,Object? homeZipCode = freezed,Object? autoUpdatePosition = null,Object? countryCode = freezed,Object? languageCode = freezed,Object? routeSegmentKm = null,Object? avoidHighways = null,Object? routeDetourBudgetKm = null,Object? minRouteSavingPerLiter = null,Object? showFuel = null,Object? showElectric = null,Object? ratingMode = null,Object? preferredAmenities = null,Object? defaultVehicleId = freezed,Object? hybridFuelChoice = freezed,Object? showConsumptionTab = null,Object? gamificationEnabled = null,Object? approachRadiusKm = null,Object? approachPriceMode = null,Object? approachMinPollSeconds = null,}) {
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
as bool,routeDetourBudgetKm: null == routeDetourBudgetKm ? _self.routeDetourBudgetKm : routeDetourBudgetKm // ignore: cast_nullable_to_non_nullable
as double,minRouteSavingPerLiter: null == minRouteSavingPerLiter ? _self.minRouteSavingPerLiter : minRouteSavingPerLiter // ignore: cast_nullable_to_non_nullable
as double,showFuel: null == showFuel ? _self.showFuel : showFuel // ignore: cast_nullable_to_non_nullable
as bool,showElectric: null == showElectric ? _self.showElectric : showElectric // ignore: cast_nullable_to_non_nullable
as bool,ratingMode: null == ratingMode ? _self.ratingMode : ratingMode // ignore: cast_nullable_to_non_nullable
as String,preferredAmenities: null == preferredAmenities ? _self._preferredAmenities : preferredAmenities // ignore: cast_nullable_to_non_nullable
as List<StationAmenity>,defaultVehicleId: freezed == defaultVehicleId ? _self.defaultVehicleId : defaultVehicleId // ignore: cast_nullable_to_non_nullable
as String?,hybridFuelChoice: freezed == hybridFuelChoice ? _self.hybridFuelChoice : hybridFuelChoice // ignore: cast_nullable_to_non_nullable
as FuelType?,showConsumptionTab: null == showConsumptionTab ? _self.showConsumptionTab : showConsumptionTab // ignore: cast_nullable_to_non_nullable
as bool,gamificationEnabled: null == gamificationEnabled ? _self.gamificationEnabled : gamificationEnabled // ignore: cast_nullable_to_non_nullable
as bool,approachRadiusKm: null == approachRadiusKm ? _self.approachRadiusKm : approachRadiusKm // ignore: cast_nullable_to_non_nullable
as double,approachPriceMode: null == approachPriceMode ? _self.approachPriceMode : approachPriceMode // ignore: cast_nullable_to_non_nullable
as ApproachPriceMode,approachMinPollSeconds: null == approachMinPollSeconds ? _self.approachMinPollSeconds : approachMinPollSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
