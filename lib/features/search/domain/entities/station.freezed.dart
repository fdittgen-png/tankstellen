// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'station.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Station {

 String get id; String get name; String get brand; String get street; String? get houseNumber;@JsonKey(fromJson: _postCodeToString) String get postCode; String get place; double get lat; double get lng; double get dist;@JsonKey(fromJson: _priceFromJson) double? get e5;@JsonKey(fromJson: _priceFromJson) double? get e10;@JsonKey(fromJson: _priceFromJson) double? get e98;@JsonKey(fromJson: _priceFromJson) double? get diesel;@JsonKey(fromJson: _priceFromJson) double? get dieselPremium;@JsonKey(fromJson: _priceFromJson) double? get e85;@JsonKey(fromJson: _priceFromJson) double? get lpg;@JsonKey(fromJson: _priceFromJson) double? get cng; bool get isOpen; String? get updatedAt; String? get openingHoursText;// "Lun 07:00-18:30, Mar 07:00-18:30..."
 bool get is24h; List<String> get services; List<String> get availableFuels; List<String> get unavailableFuels; String? get stationType;// "R" retail, "A" autoroute
 String? get department; String? get region;@JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson) Set<StationAmenity> get amenities;
/// Create a copy of Station
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StationCopyWith<Station> get copyWith => _$StationCopyWithImpl<Station>(this as Station, _$identity);

  /// Serializes this Station to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Station&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.street, street) || other.street == street)&&(identical(other.houseNumber, houseNumber) || other.houseNumber == houseNumber)&&(identical(other.postCode, postCode) || other.postCode == postCode)&&(identical(other.place, place) || other.place == place)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.dist, dist) || other.dist == dist)&&(identical(other.e5, e5) || other.e5 == e5)&&(identical(other.e10, e10) || other.e10 == e10)&&(identical(other.e98, e98) || other.e98 == e98)&&(identical(other.diesel, diesel) || other.diesel == diesel)&&(identical(other.dieselPremium, dieselPremium) || other.dieselPremium == dieselPremium)&&(identical(other.e85, e85) || other.e85 == e85)&&(identical(other.lpg, lpg) || other.lpg == lpg)&&(identical(other.cng, cng) || other.cng == cng)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.openingHoursText, openingHoursText) || other.openingHoursText == openingHoursText)&&(identical(other.is24h, is24h) || other.is24h == is24h)&&const DeepCollectionEquality().equals(other.services, services)&&const DeepCollectionEquality().equals(other.availableFuels, availableFuels)&&const DeepCollectionEquality().equals(other.unavailableFuels, unavailableFuels)&&(identical(other.stationType, stationType) || other.stationType == stationType)&&(identical(other.department, department) || other.department == department)&&(identical(other.region, region) || other.region == region)&&const DeepCollectionEquality().equals(other.amenities, amenities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,brand,street,houseNumber,postCode,place,lat,lng,dist,e5,e10,e98,diesel,dieselPremium,e85,lpg,cng,isOpen,updatedAt,openingHoursText,is24h,const DeepCollectionEquality().hash(services),const DeepCollectionEquality().hash(availableFuels),const DeepCollectionEquality().hash(unavailableFuels),stationType,department,region,const DeepCollectionEquality().hash(amenities)]);

@override
String toString() {
  return 'Station(id: $id, name: $name, brand: $brand, street: $street, houseNumber: $houseNumber, postCode: $postCode, place: $place, lat: $lat, lng: $lng, dist: $dist, e5: $e5, e10: $e10, e98: $e98, diesel: $diesel, dieselPremium: $dieselPremium, e85: $e85, lpg: $lpg, cng: $cng, isOpen: $isOpen, updatedAt: $updatedAt, openingHoursText: $openingHoursText, is24h: $is24h, services: $services, availableFuels: $availableFuels, unavailableFuels: $unavailableFuels, stationType: $stationType, department: $department, region: $region, amenities: $amenities)';
}


}

/// @nodoc
abstract mixin class $StationCopyWith<$Res>  {
  factory $StationCopyWith(Station value, $Res Function(Station) _then) = _$StationCopyWithImpl;
@useResult
$Res call({
 String id, String name, String brand, String street, String? houseNumber,@JsonKey(fromJson: _postCodeToString) String postCode, String place, double lat, double lng, double dist,@JsonKey(fromJson: _priceFromJson) double? e5,@JsonKey(fromJson: _priceFromJson) double? e10,@JsonKey(fromJson: _priceFromJson) double? e98,@JsonKey(fromJson: _priceFromJson) double? diesel,@JsonKey(fromJson: _priceFromJson) double? dieselPremium,@JsonKey(fromJson: _priceFromJson) double? e85,@JsonKey(fromJson: _priceFromJson) double? lpg,@JsonKey(fromJson: _priceFromJson) double? cng, bool isOpen, String? updatedAt, String? openingHoursText, bool is24h, List<String> services, List<String> availableFuels, List<String> unavailableFuels, String? stationType, String? department, String? region,@JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson) Set<StationAmenity> amenities
});




}
/// @nodoc
class _$StationCopyWithImpl<$Res>
    implements $StationCopyWith<$Res> {
  _$StationCopyWithImpl(this._self, this._then);

  final Station _self;
  final $Res Function(Station) _then;

/// Create a copy of Station
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? brand = null,Object? street = null,Object? houseNumber = freezed,Object? postCode = null,Object? place = null,Object? lat = null,Object? lng = null,Object? dist = null,Object? e5 = freezed,Object? e10 = freezed,Object? e98 = freezed,Object? diesel = freezed,Object? dieselPremium = freezed,Object? e85 = freezed,Object? lpg = freezed,Object? cng = freezed,Object? isOpen = null,Object? updatedAt = freezed,Object? openingHoursText = freezed,Object? is24h = null,Object? services = null,Object? availableFuels = null,Object? unavailableFuels = null,Object? stationType = freezed,Object? department = freezed,Object? region = freezed,Object? amenities = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,houseNumber: freezed == houseNumber ? _self.houseNumber : houseNumber // ignore: cast_nullable_to_non_nullable
as String?,postCode: null == postCode ? _self.postCode : postCode // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,dist: null == dist ? _self.dist : dist // ignore: cast_nullable_to_non_nullable
as double,e5: freezed == e5 ? _self.e5 : e5 // ignore: cast_nullable_to_non_nullable
as double?,e10: freezed == e10 ? _self.e10 : e10 // ignore: cast_nullable_to_non_nullable
as double?,e98: freezed == e98 ? _self.e98 : e98 // ignore: cast_nullable_to_non_nullable
as double?,diesel: freezed == diesel ? _self.diesel : diesel // ignore: cast_nullable_to_non_nullable
as double?,dieselPremium: freezed == dieselPremium ? _self.dieselPremium : dieselPremium // ignore: cast_nullable_to_non_nullable
as double?,e85: freezed == e85 ? _self.e85 : e85 // ignore: cast_nullable_to_non_nullable
as double?,lpg: freezed == lpg ? _self.lpg : lpg // ignore: cast_nullable_to_non_nullable
as double?,cng: freezed == cng ? _self.cng : cng // ignore: cast_nullable_to_non_nullable
as double?,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,openingHoursText: freezed == openingHoursText ? _self.openingHoursText : openingHoursText // ignore: cast_nullable_to_non_nullable
as String?,is24h: null == is24h ? _self.is24h : is24h // ignore: cast_nullable_to_non_nullable
as bool,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<String>,availableFuels: null == availableFuels ? _self.availableFuels : availableFuels // ignore: cast_nullable_to_non_nullable
as List<String>,unavailableFuels: null == unavailableFuels ? _self.unavailableFuels : unavailableFuels // ignore: cast_nullable_to_non_nullable
as List<String>,stationType: freezed == stationType ? _self.stationType : stationType // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as Set<StationAmenity>,
  ));
}

}


/// Adds pattern-matching-related methods to [Station].
extension StationPatterns on Station {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Station value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Station() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Station value)  $default,){
final _that = this;
switch (_that) {
case _Station():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Station value)?  $default,){
final _that = this;
switch (_that) {
case _Station() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String brand,  String street,  String? houseNumber, @JsonKey(fromJson: _postCodeToString)  String postCode,  String place,  double lat,  double lng,  double dist, @JsonKey(fromJson: _priceFromJson)  double? e5, @JsonKey(fromJson: _priceFromJson)  double? e10, @JsonKey(fromJson: _priceFromJson)  double? e98, @JsonKey(fromJson: _priceFromJson)  double? diesel, @JsonKey(fromJson: _priceFromJson)  double? dieselPremium, @JsonKey(fromJson: _priceFromJson)  double? e85, @JsonKey(fromJson: _priceFromJson)  double? lpg, @JsonKey(fromJson: _priceFromJson)  double? cng,  bool isOpen,  String? updatedAt,  String? openingHoursText,  bool is24h,  List<String> services,  List<String> availableFuels,  List<String> unavailableFuels,  String? stationType,  String? department,  String? region, @JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson)  Set<StationAmenity> amenities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Station() when $default != null:
return $default(_that.id,_that.name,_that.brand,_that.street,_that.houseNumber,_that.postCode,_that.place,_that.lat,_that.lng,_that.dist,_that.e5,_that.e10,_that.e98,_that.diesel,_that.dieselPremium,_that.e85,_that.lpg,_that.cng,_that.isOpen,_that.updatedAt,_that.openingHoursText,_that.is24h,_that.services,_that.availableFuels,_that.unavailableFuels,_that.stationType,_that.department,_that.region,_that.amenities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String brand,  String street,  String? houseNumber, @JsonKey(fromJson: _postCodeToString)  String postCode,  String place,  double lat,  double lng,  double dist, @JsonKey(fromJson: _priceFromJson)  double? e5, @JsonKey(fromJson: _priceFromJson)  double? e10, @JsonKey(fromJson: _priceFromJson)  double? e98, @JsonKey(fromJson: _priceFromJson)  double? diesel, @JsonKey(fromJson: _priceFromJson)  double? dieselPremium, @JsonKey(fromJson: _priceFromJson)  double? e85, @JsonKey(fromJson: _priceFromJson)  double? lpg, @JsonKey(fromJson: _priceFromJson)  double? cng,  bool isOpen,  String? updatedAt,  String? openingHoursText,  bool is24h,  List<String> services,  List<String> availableFuels,  List<String> unavailableFuels,  String? stationType,  String? department,  String? region, @JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson)  Set<StationAmenity> amenities)  $default,) {final _that = this;
switch (_that) {
case _Station():
return $default(_that.id,_that.name,_that.brand,_that.street,_that.houseNumber,_that.postCode,_that.place,_that.lat,_that.lng,_that.dist,_that.e5,_that.e10,_that.e98,_that.diesel,_that.dieselPremium,_that.e85,_that.lpg,_that.cng,_that.isOpen,_that.updatedAt,_that.openingHoursText,_that.is24h,_that.services,_that.availableFuels,_that.unavailableFuels,_that.stationType,_that.department,_that.region,_that.amenities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String brand,  String street,  String? houseNumber, @JsonKey(fromJson: _postCodeToString)  String postCode,  String place,  double lat,  double lng,  double dist, @JsonKey(fromJson: _priceFromJson)  double? e5, @JsonKey(fromJson: _priceFromJson)  double? e10, @JsonKey(fromJson: _priceFromJson)  double? e98, @JsonKey(fromJson: _priceFromJson)  double? diesel, @JsonKey(fromJson: _priceFromJson)  double? dieselPremium, @JsonKey(fromJson: _priceFromJson)  double? e85, @JsonKey(fromJson: _priceFromJson)  double? lpg, @JsonKey(fromJson: _priceFromJson)  double? cng,  bool isOpen,  String? updatedAt,  String? openingHoursText,  bool is24h,  List<String> services,  List<String> availableFuels,  List<String> unavailableFuels,  String? stationType,  String? department,  String? region, @JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson)  Set<StationAmenity> amenities)?  $default,) {final _that = this;
switch (_that) {
case _Station() when $default != null:
return $default(_that.id,_that.name,_that.brand,_that.street,_that.houseNumber,_that.postCode,_that.place,_that.lat,_that.lng,_that.dist,_that.e5,_that.e10,_that.e98,_that.diesel,_that.dieselPremium,_that.e85,_that.lpg,_that.cng,_that.isOpen,_that.updatedAt,_that.openingHoursText,_that.is24h,_that.services,_that.availableFuels,_that.unavailableFuels,_that.stationType,_that.department,_that.region,_that.amenities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Station implements Station {
  const _Station({required this.id, required this.name, required this.brand, required this.street, this.houseNumber, @JsonKey(fromJson: _postCodeToString) required this.postCode, required this.place, required this.lat, required this.lng, this.dist = 0, @JsonKey(fromJson: _priceFromJson) this.e5, @JsonKey(fromJson: _priceFromJson) this.e10, @JsonKey(fromJson: _priceFromJson) this.e98, @JsonKey(fromJson: _priceFromJson) this.diesel, @JsonKey(fromJson: _priceFromJson) this.dieselPremium, @JsonKey(fromJson: _priceFromJson) this.e85, @JsonKey(fromJson: _priceFromJson) this.lpg, @JsonKey(fromJson: _priceFromJson) this.cng, required this.isOpen, this.updatedAt, this.openingHoursText, this.is24h = false, final  List<String> services = const [], final  List<String> availableFuels = const [], final  List<String> unavailableFuels = const [], this.stationType, this.department, this.region, @JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson) final  Set<StationAmenity> amenities = const {}}): _services = services,_availableFuels = availableFuels,_unavailableFuels = unavailableFuels,_amenities = amenities;
  factory _Station.fromJson(Map<String, dynamic> json) => _$StationFromJson(json);

@override final  String id;
@override final  String name;
@override final  String brand;
@override final  String street;
@override final  String? houseNumber;
@override@JsonKey(fromJson: _postCodeToString) final  String postCode;
@override final  String place;
@override final  double lat;
@override final  double lng;
@override@JsonKey() final  double dist;
@override@JsonKey(fromJson: _priceFromJson) final  double? e5;
@override@JsonKey(fromJson: _priceFromJson) final  double? e10;
@override@JsonKey(fromJson: _priceFromJson) final  double? e98;
@override@JsonKey(fromJson: _priceFromJson) final  double? diesel;
@override@JsonKey(fromJson: _priceFromJson) final  double? dieselPremium;
@override@JsonKey(fromJson: _priceFromJson) final  double? e85;
@override@JsonKey(fromJson: _priceFromJson) final  double? lpg;
@override@JsonKey(fromJson: _priceFromJson) final  double? cng;
@override final  bool isOpen;
@override final  String? updatedAt;
@override final  String? openingHoursText;
// "Lun 07:00-18:30, Mar 07:00-18:30..."
@override@JsonKey() final  bool is24h;
 final  List<String> _services;
@override@JsonKey() List<String> get services {
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_services);
}

 final  List<String> _availableFuels;
@override@JsonKey() List<String> get availableFuels {
  if (_availableFuels is EqualUnmodifiableListView) return _availableFuels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableFuels);
}

 final  List<String> _unavailableFuels;
@override@JsonKey() List<String> get unavailableFuels {
  if (_unavailableFuels is EqualUnmodifiableListView) return _unavailableFuels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unavailableFuels);
}

@override final  String? stationType;
// "R" retail, "A" autoroute
@override final  String? department;
@override final  String? region;
 final  Set<StationAmenity> _amenities;
@override@JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson) Set<StationAmenity> get amenities {
  if (_amenities is EqualUnmodifiableSetView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_amenities);
}


/// Create a copy of Station
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StationCopyWith<_Station> get copyWith => __$StationCopyWithImpl<_Station>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Station&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.street, street) || other.street == street)&&(identical(other.houseNumber, houseNumber) || other.houseNumber == houseNumber)&&(identical(other.postCode, postCode) || other.postCode == postCode)&&(identical(other.place, place) || other.place == place)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.dist, dist) || other.dist == dist)&&(identical(other.e5, e5) || other.e5 == e5)&&(identical(other.e10, e10) || other.e10 == e10)&&(identical(other.e98, e98) || other.e98 == e98)&&(identical(other.diesel, diesel) || other.diesel == diesel)&&(identical(other.dieselPremium, dieselPremium) || other.dieselPremium == dieselPremium)&&(identical(other.e85, e85) || other.e85 == e85)&&(identical(other.lpg, lpg) || other.lpg == lpg)&&(identical(other.cng, cng) || other.cng == cng)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.openingHoursText, openingHoursText) || other.openingHoursText == openingHoursText)&&(identical(other.is24h, is24h) || other.is24h == is24h)&&const DeepCollectionEquality().equals(other._services, _services)&&const DeepCollectionEquality().equals(other._availableFuels, _availableFuels)&&const DeepCollectionEquality().equals(other._unavailableFuels, _unavailableFuels)&&(identical(other.stationType, stationType) || other.stationType == stationType)&&(identical(other.department, department) || other.department == department)&&(identical(other.region, region) || other.region == region)&&const DeepCollectionEquality().equals(other._amenities, _amenities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,brand,street,houseNumber,postCode,place,lat,lng,dist,e5,e10,e98,diesel,dieselPremium,e85,lpg,cng,isOpen,updatedAt,openingHoursText,is24h,const DeepCollectionEquality().hash(_services),const DeepCollectionEquality().hash(_availableFuels),const DeepCollectionEquality().hash(_unavailableFuels),stationType,department,region,const DeepCollectionEquality().hash(_amenities)]);

@override
String toString() {
  return 'Station(id: $id, name: $name, brand: $brand, street: $street, houseNumber: $houseNumber, postCode: $postCode, place: $place, lat: $lat, lng: $lng, dist: $dist, e5: $e5, e10: $e10, e98: $e98, diesel: $diesel, dieselPremium: $dieselPremium, e85: $e85, lpg: $lpg, cng: $cng, isOpen: $isOpen, updatedAt: $updatedAt, openingHoursText: $openingHoursText, is24h: $is24h, services: $services, availableFuels: $availableFuels, unavailableFuels: $unavailableFuels, stationType: $stationType, department: $department, region: $region, amenities: $amenities)';
}


}

/// @nodoc
abstract mixin class _$StationCopyWith<$Res> implements $StationCopyWith<$Res> {
  factory _$StationCopyWith(_Station value, $Res Function(_Station) _then) = __$StationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String brand, String street, String? houseNumber,@JsonKey(fromJson: _postCodeToString) String postCode, String place, double lat, double lng, double dist,@JsonKey(fromJson: _priceFromJson) double? e5,@JsonKey(fromJson: _priceFromJson) double? e10,@JsonKey(fromJson: _priceFromJson) double? e98,@JsonKey(fromJson: _priceFromJson) double? diesel,@JsonKey(fromJson: _priceFromJson) double? dieselPremium,@JsonKey(fromJson: _priceFromJson) double? e85,@JsonKey(fromJson: _priceFromJson) double? lpg,@JsonKey(fromJson: _priceFromJson) double? cng, bool isOpen, String? updatedAt, String? openingHoursText, bool is24h, List<String> services, List<String> availableFuels, List<String> unavailableFuels, String? stationType, String? department, String? region,@JsonKey(fromJson: _amenitiesFromJson, toJson: _amenitiesToJson) Set<StationAmenity> amenities
});




}
/// @nodoc
class __$StationCopyWithImpl<$Res>
    implements _$StationCopyWith<$Res> {
  __$StationCopyWithImpl(this._self, this._then);

  final _Station _self;
  final $Res Function(_Station) _then;

/// Create a copy of Station
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? brand = null,Object? street = null,Object? houseNumber = freezed,Object? postCode = null,Object? place = null,Object? lat = null,Object? lng = null,Object? dist = null,Object? e5 = freezed,Object? e10 = freezed,Object? e98 = freezed,Object? diesel = freezed,Object? dieselPremium = freezed,Object? e85 = freezed,Object? lpg = freezed,Object? cng = freezed,Object? isOpen = null,Object? updatedAt = freezed,Object? openingHoursText = freezed,Object? is24h = null,Object? services = null,Object? availableFuels = null,Object? unavailableFuels = null,Object? stationType = freezed,Object? department = freezed,Object? region = freezed,Object? amenities = null,}) {
  return _then(_Station(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,street: null == street ? _self.street : street // ignore: cast_nullable_to_non_nullable
as String,houseNumber: freezed == houseNumber ? _self.houseNumber : houseNumber // ignore: cast_nullable_to_non_nullable
as String?,postCode: null == postCode ? _self.postCode : postCode // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,dist: null == dist ? _self.dist : dist // ignore: cast_nullable_to_non_nullable
as double,e5: freezed == e5 ? _self.e5 : e5 // ignore: cast_nullable_to_non_nullable
as double?,e10: freezed == e10 ? _self.e10 : e10 // ignore: cast_nullable_to_non_nullable
as double?,e98: freezed == e98 ? _self.e98 : e98 // ignore: cast_nullable_to_non_nullable
as double?,diesel: freezed == diesel ? _self.diesel : diesel // ignore: cast_nullable_to_non_nullable
as double?,dieselPremium: freezed == dieselPremium ? _self.dieselPremium : dieselPremium // ignore: cast_nullable_to_non_nullable
as double?,e85: freezed == e85 ? _self.e85 : e85 // ignore: cast_nullable_to_non_nullable
as double?,lpg: freezed == lpg ? _self.lpg : lpg // ignore: cast_nullable_to_non_nullable
as double?,cng: freezed == cng ? _self.cng : cng // ignore: cast_nullable_to_non_nullable
as double?,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,openingHoursText: freezed == openingHoursText ? _self.openingHoursText : openingHoursText // ignore: cast_nullable_to_non_nullable
as String?,is24h: null == is24h ? _self.is24h : is24h // ignore: cast_nullable_to_non_nullable
as bool,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<String>,availableFuels: null == availableFuels ? _self._availableFuels : availableFuels // ignore: cast_nullable_to_non_nullable
as List<String>,unavailableFuels: null == unavailableFuels ? _self._unavailableFuels : unavailableFuels // ignore: cast_nullable_to_non_nullable
as List<String>,stationType: freezed == stationType ? _self.stationType : stationType // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as Set<StationAmenity>,
  ));
}


}

/// @nodoc
mixin _$StationDetail {

 Station get station; List<OpeningTime> get openingTimes; List<String> get overrides; bool get wholeDay; String? get state;
/// Create a copy of StationDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StationDetailCopyWith<StationDetail> get copyWith => _$StationDetailCopyWithImpl<StationDetail>(this as StationDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StationDetail&&(identical(other.station, station) || other.station == station)&&const DeepCollectionEquality().equals(other.openingTimes, openingTimes)&&const DeepCollectionEquality().equals(other.overrides, overrides)&&(identical(other.wholeDay, wholeDay) || other.wholeDay == wholeDay)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,station,const DeepCollectionEquality().hash(openingTimes),const DeepCollectionEquality().hash(overrides),wholeDay,state);

@override
String toString() {
  return 'StationDetail(station: $station, openingTimes: $openingTimes, overrides: $overrides, wholeDay: $wholeDay, state: $state)';
}


}

/// @nodoc
abstract mixin class $StationDetailCopyWith<$Res>  {
  factory $StationDetailCopyWith(StationDetail value, $Res Function(StationDetail) _then) = _$StationDetailCopyWithImpl;
@useResult
$Res call({
 Station station, List<OpeningTime> openingTimes, List<String> overrides, bool wholeDay, String? state
});


$StationCopyWith<$Res> get station;

}
/// @nodoc
class _$StationDetailCopyWithImpl<$Res>
    implements $StationDetailCopyWith<$Res> {
  _$StationDetailCopyWithImpl(this._self, this._then);

  final StationDetail _self;
  final $Res Function(StationDetail) _then;

/// Create a copy of StationDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? station = null,Object? openingTimes = null,Object? overrides = null,Object? wholeDay = null,Object? state = freezed,}) {
  return _then(_self.copyWith(
station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as Station,openingTimes: null == openingTimes ? _self.openingTimes : openingTimes // ignore: cast_nullable_to_non_nullable
as List<OpeningTime>,overrides: null == overrides ? _self.overrides : overrides // ignore: cast_nullable_to_non_nullable
as List<String>,wholeDay: null == wholeDay ? _self.wholeDay : wholeDay // ignore: cast_nullable_to_non_nullable
as bool,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of StationDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StationCopyWith<$Res> get station {
  
  return $StationCopyWith<$Res>(_self.station, (value) {
    return _then(_self.copyWith(station: value));
  });
}
}


/// Adds pattern-matching-related methods to [StationDetail].
extension StationDetailPatterns on StationDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StationDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StationDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StationDetail value)  $default,){
final _that = this;
switch (_that) {
case _StationDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StationDetail value)?  $default,){
final _that = this;
switch (_that) {
case _StationDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Station station,  List<OpeningTime> openingTimes,  List<String> overrides,  bool wholeDay,  String? state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StationDetail() when $default != null:
return $default(_that.station,_that.openingTimes,_that.overrides,_that.wholeDay,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Station station,  List<OpeningTime> openingTimes,  List<String> overrides,  bool wholeDay,  String? state)  $default,) {final _that = this;
switch (_that) {
case _StationDetail():
return $default(_that.station,_that.openingTimes,_that.overrides,_that.wholeDay,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Station station,  List<OpeningTime> openingTimes,  List<String> overrides,  bool wholeDay,  String? state)?  $default,) {final _that = this;
switch (_that) {
case _StationDetail() when $default != null:
return $default(_that.station,_that.openingTimes,_that.overrides,_that.wholeDay,_that.state);case _:
  return null;

}
}

}

/// @nodoc


class _StationDetail implements StationDetail {
  const _StationDetail({required this.station, final  List<OpeningTime> openingTimes = const [], final  List<String> overrides = const [], this.wholeDay = false, this.state}): _openingTimes = openingTimes,_overrides = overrides;
  

@override final  Station station;
 final  List<OpeningTime> _openingTimes;
@override@JsonKey() List<OpeningTime> get openingTimes {
  if (_openingTimes is EqualUnmodifiableListView) return _openingTimes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_openingTimes);
}

 final  List<String> _overrides;
@override@JsonKey() List<String> get overrides {
  if (_overrides is EqualUnmodifiableListView) return _overrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overrides);
}

@override@JsonKey() final  bool wholeDay;
@override final  String? state;

/// Create a copy of StationDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StationDetailCopyWith<_StationDetail> get copyWith => __$StationDetailCopyWithImpl<_StationDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StationDetail&&(identical(other.station, station) || other.station == station)&&const DeepCollectionEquality().equals(other._openingTimes, _openingTimes)&&const DeepCollectionEquality().equals(other._overrides, _overrides)&&(identical(other.wholeDay, wholeDay) || other.wholeDay == wholeDay)&&(identical(other.state, state) || other.state == state));
}


@override
int get hashCode => Object.hash(runtimeType,station,const DeepCollectionEquality().hash(_openingTimes),const DeepCollectionEquality().hash(_overrides),wholeDay,state);

@override
String toString() {
  return 'StationDetail(station: $station, openingTimes: $openingTimes, overrides: $overrides, wholeDay: $wholeDay, state: $state)';
}


}

/// @nodoc
abstract mixin class _$StationDetailCopyWith<$Res> implements $StationDetailCopyWith<$Res> {
  factory _$StationDetailCopyWith(_StationDetail value, $Res Function(_StationDetail) _then) = __$StationDetailCopyWithImpl;
@override @useResult
$Res call({
 Station station, List<OpeningTime> openingTimes, List<String> overrides, bool wholeDay, String? state
});


@override $StationCopyWith<$Res> get station;

}
/// @nodoc
class __$StationDetailCopyWithImpl<$Res>
    implements _$StationDetailCopyWith<$Res> {
  __$StationDetailCopyWithImpl(this._self, this._then);

  final _StationDetail _self;
  final $Res Function(_StationDetail) _then;

/// Create a copy of StationDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? station = null,Object? openingTimes = null,Object? overrides = null,Object? wholeDay = null,Object? state = freezed,}) {
  return _then(_StationDetail(
station: null == station ? _self.station : station // ignore: cast_nullable_to_non_nullable
as Station,openingTimes: null == openingTimes ? _self._openingTimes : openingTimes // ignore: cast_nullable_to_non_nullable
as List<OpeningTime>,overrides: null == overrides ? _self._overrides : overrides // ignore: cast_nullable_to_non_nullable
as List<String>,wholeDay: null == wholeDay ? _self.wholeDay : wholeDay // ignore: cast_nullable_to_non_nullable
as bool,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of StationDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StationCopyWith<$Res> get station {
  
  return $StationCopyWith<$Res>(_self.station, (value) {
    return _then(_self.copyWith(station: value));
  });
}
}


/// @nodoc
mixin _$OpeningTime {

 String get text; String get start; String get end;
/// Create a copy of OpeningTime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpeningTimeCopyWith<OpeningTime> get copyWith => _$OpeningTimeCopyWithImpl<OpeningTime>(this as OpeningTime, _$identity);

  /// Serializes this OpeningTime to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpeningTime&&(identical(other.text, text) || other.text == text)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,start,end);

@override
String toString() {
  return 'OpeningTime(text: $text, start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class $OpeningTimeCopyWith<$Res>  {
  factory $OpeningTimeCopyWith(OpeningTime value, $Res Function(OpeningTime) _then) = _$OpeningTimeCopyWithImpl;
@useResult
$Res call({
 String text, String start, String end
});




}
/// @nodoc
class _$OpeningTimeCopyWithImpl<$Res>
    implements $OpeningTimeCopyWith<$Res> {
  _$OpeningTimeCopyWithImpl(this._self, this._then);

  final OpeningTime _self;
  final $Res Function(OpeningTime) _then;

/// Create a copy of OpeningTime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? start = null,Object? end = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OpeningTime].
extension OpeningTimePatterns on OpeningTime {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpeningTime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpeningTime() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpeningTime value)  $default,){
final _that = this;
switch (_that) {
case _OpeningTime():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpeningTime value)?  $default,){
final _that = this;
switch (_that) {
case _OpeningTime() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String start,  String end)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpeningTime() when $default != null:
return $default(_that.text,_that.start,_that.end);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String start,  String end)  $default,) {final _that = this;
switch (_that) {
case _OpeningTime():
return $default(_that.text,_that.start,_that.end);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String start,  String end)?  $default,) {final _that = this;
switch (_that) {
case _OpeningTime() when $default != null:
return $default(_that.text,_that.start,_that.end);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpeningTime implements OpeningTime {
  const _OpeningTime({required this.text, required this.start, required this.end});
  factory _OpeningTime.fromJson(Map<String, dynamic> json) => _$OpeningTimeFromJson(json);

@override final  String text;
@override final  String start;
@override final  String end;

/// Create a copy of OpeningTime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpeningTimeCopyWith<_OpeningTime> get copyWith => __$OpeningTimeCopyWithImpl<_OpeningTime>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpeningTimeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpeningTime&&(identical(other.text, text) || other.text == text)&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,start,end);

@override
String toString() {
  return 'OpeningTime(text: $text, start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class _$OpeningTimeCopyWith<$Res> implements $OpeningTimeCopyWith<$Res> {
  factory _$OpeningTimeCopyWith(_OpeningTime value, $Res Function(_OpeningTime) _then) = __$OpeningTimeCopyWithImpl;
@override @useResult
$Res call({
 String text, String start, String end
});




}
/// @nodoc
class __$OpeningTimeCopyWithImpl<$Res>
    implements _$OpeningTimeCopyWith<$Res> {
  __$OpeningTimeCopyWithImpl(this._self, this._then);

  final _OpeningTime _self;
  final $Res Function(_OpeningTime) _then;

/// Create a copy of OpeningTime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? start = null,Object? end = null,}) {
  return _then(_OpeningTime(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as String,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
