// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'charging_station.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EvConnector {

 String get id;@ConnectorTypeJsonConverter() ConnectorType get type; double get maxPowerKw;@ConnectorStatusJsonConverter() ConnectorStatus get status; String? get tariffId;/// Original free-form type label as returned by the upstream API
/// (e.g. "CCS Type 2", "Tesla Supercharger"). Preserved so the UI
/// can show the more specific label when it exists, falling back to
/// [type] via [ConnectorType.label].
 String? get rawType;/// "AC", "DC", "AC/DC" — preserved from OpenChargeMap responses.
 String? get currentType;/// Number of physical connectors of this type at the station.
 int get quantity;/// Original free-form status label returned by the upstream API
/// (e.g. "Currently Available"). Preserved so the UI can show the
/// specific label when present.
 String? get statusLabel;
/// Create a copy of EvConnector
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvConnectorCopyWith<EvConnector> get copyWith => _$EvConnectorCopyWithImpl<EvConnector>(this as EvConnector, _$identity);

  /// Serializes this EvConnector to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvConnector&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.maxPowerKw, maxPowerKw) || other.maxPowerKw == maxPowerKw)&&(identical(other.status, status) || other.status == status)&&(identical(other.tariffId, tariffId) || other.tariffId == tariffId)&&(identical(other.rawType, rawType) || other.rawType == rawType)&&(identical(other.currentType, currentType) || other.currentType == currentType)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,maxPowerKw,status,tariffId,rawType,currentType,quantity,statusLabel);

@override
String toString() {
  return 'EvConnector(id: $id, type: $type, maxPowerKw: $maxPowerKw, status: $status, tariffId: $tariffId, rawType: $rawType, currentType: $currentType, quantity: $quantity, statusLabel: $statusLabel)';
}


}

/// @nodoc
abstract mixin class $EvConnectorCopyWith<$Res>  {
  factory $EvConnectorCopyWith(EvConnector value, $Res Function(EvConnector) _then) = _$EvConnectorCopyWithImpl;
@useResult
$Res call({
 String id,@ConnectorTypeJsonConverter() ConnectorType type, double maxPowerKw,@ConnectorStatusJsonConverter() ConnectorStatus status, String? tariffId, String? rawType, String? currentType, int quantity, String? statusLabel
});




}
/// @nodoc
class _$EvConnectorCopyWithImpl<$Res>
    implements $EvConnectorCopyWith<$Res> {
  _$EvConnectorCopyWithImpl(this._self, this._then);

  final EvConnector _self;
  final $Res Function(EvConnector) _then;

/// Create a copy of EvConnector
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? maxPowerKw = null,Object? status = null,Object? tariffId = freezed,Object? rawType = freezed,Object? currentType = freezed,Object? quantity = null,Object? statusLabel = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ConnectorType,maxPowerKw: null == maxPowerKw ? _self.maxPowerKw : maxPowerKw // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectorStatus,tariffId: freezed == tariffId ? _self.tariffId : tariffId // ignore: cast_nullable_to_non_nullable
as String?,rawType: freezed == rawType ? _self.rawType : rawType // ignore: cast_nullable_to_non_nullable
as String?,currentType: freezed == currentType ? _self.currentType : currentType // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EvConnector].
extension EvConnectorPatterns on EvConnector {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EvConnector value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EvConnector() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EvConnector value)  $default,){
final _that = this;
switch (_that) {
case _EvConnector():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EvConnector value)?  $default,){
final _that = this;
switch (_that) {
case _EvConnector() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @ConnectorTypeJsonConverter()  ConnectorType type,  double maxPowerKw, @ConnectorStatusJsonConverter()  ConnectorStatus status,  String? tariffId,  String? rawType,  String? currentType,  int quantity,  String? statusLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EvConnector() when $default != null:
return $default(_that.id,_that.type,_that.maxPowerKw,_that.status,_that.tariffId,_that.rawType,_that.currentType,_that.quantity,_that.statusLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @ConnectorTypeJsonConverter()  ConnectorType type,  double maxPowerKw, @ConnectorStatusJsonConverter()  ConnectorStatus status,  String? tariffId,  String? rawType,  String? currentType,  int quantity,  String? statusLabel)  $default,) {final _that = this;
switch (_that) {
case _EvConnector():
return $default(_that.id,_that.type,_that.maxPowerKw,_that.status,_that.tariffId,_that.rawType,_that.currentType,_that.quantity,_that.statusLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @ConnectorTypeJsonConverter()  ConnectorType type,  double maxPowerKw, @ConnectorStatusJsonConverter()  ConnectorStatus status,  String? tariffId,  String? rawType,  String? currentType,  int quantity,  String? statusLabel)?  $default,) {final _that = this;
switch (_that) {
case _EvConnector() when $default != null:
return $default(_that.id,_that.type,_that.maxPowerKw,_that.status,_that.tariffId,_that.rawType,_that.currentType,_that.quantity,_that.statusLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EvConnector extends EvConnector {
  const _EvConnector({this.id = '', @ConnectorTypeJsonConverter() required this.type, this.maxPowerKw = 0, @ConnectorStatusJsonConverter() this.status = ConnectorStatus.unknown, this.tariffId, this.rawType, this.currentType, this.quantity = 0, this.statusLabel}): super._();
  factory _EvConnector.fromJson(Map<String, dynamic> json) => _$EvConnectorFromJson(json);

@override@JsonKey() final  String id;
@override@ConnectorTypeJsonConverter() final  ConnectorType type;
@override@JsonKey() final  double maxPowerKw;
@override@JsonKey()@ConnectorStatusJsonConverter() final  ConnectorStatus status;
@override final  String? tariffId;
/// Original free-form type label as returned by the upstream API
/// (e.g. "CCS Type 2", "Tesla Supercharger"). Preserved so the UI
/// can show the more specific label when it exists, falling back to
/// [type] via [ConnectorType.label].
@override final  String? rawType;
/// "AC", "DC", "AC/DC" — preserved from OpenChargeMap responses.
@override final  String? currentType;
/// Number of physical connectors of this type at the station.
@override@JsonKey() final  int quantity;
/// Original free-form status label returned by the upstream API
/// (e.g. "Currently Available"). Preserved so the UI can show the
/// specific label when present.
@override final  String? statusLabel;

/// Create a copy of EvConnector
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EvConnectorCopyWith<_EvConnector> get copyWith => __$EvConnectorCopyWithImpl<_EvConnector>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EvConnectorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EvConnector&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.maxPowerKw, maxPowerKw) || other.maxPowerKw == maxPowerKw)&&(identical(other.status, status) || other.status == status)&&(identical(other.tariffId, tariffId) || other.tariffId == tariffId)&&(identical(other.rawType, rawType) || other.rawType == rawType)&&(identical(other.currentType, currentType) || other.currentType == currentType)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,maxPowerKw,status,tariffId,rawType,currentType,quantity,statusLabel);

@override
String toString() {
  return 'EvConnector(id: $id, type: $type, maxPowerKw: $maxPowerKw, status: $status, tariffId: $tariffId, rawType: $rawType, currentType: $currentType, quantity: $quantity, statusLabel: $statusLabel)';
}


}

/// @nodoc
abstract mixin class _$EvConnectorCopyWith<$Res> implements $EvConnectorCopyWith<$Res> {
  factory _$EvConnectorCopyWith(_EvConnector value, $Res Function(_EvConnector) _then) = __$EvConnectorCopyWithImpl;
@override @useResult
$Res call({
 String id,@ConnectorTypeJsonConverter() ConnectorType type, double maxPowerKw,@ConnectorStatusJsonConverter() ConnectorStatus status, String? tariffId, String? rawType, String? currentType, int quantity, String? statusLabel
});




}
/// @nodoc
class __$EvConnectorCopyWithImpl<$Res>
    implements _$EvConnectorCopyWith<$Res> {
  __$EvConnectorCopyWithImpl(this._self, this._then);

  final _EvConnector _self;
  final $Res Function(_EvConnector) _then;

/// Create a copy of EvConnector
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? maxPowerKw = null,Object? status = null,Object? tariffId = freezed,Object? rawType = freezed,Object? currentType = freezed,Object? quantity = null,Object? statusLabel = freezed,}) {
  return _then(_EvConnector(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ConnectorType,maxPowerKw: null == maxPowerKw ? _self.maxPowerKw : maxPowerKw // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectorStatus,tariffId: freezed == tariffId ? _self.tariffId : tariffId // ignore: cast_nullable_to_non_nullable
as String?,rawType: freezed == rawType ? _self.rawType : rawType // ignore: cast_nullable_to_non_nullable
as String?,currentType: freezed == currentType ? _self.currentType : currentType // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChargingStation {

 String get id; String get name; String? get operator; double get latitude; double get longitude; String? get address;@EvConnectorListConverter() List<EvConnector> get connectors; List<String> get amenities;@OpeningHoursNullableConverter() OpeningHours? get openingHours; DateTime? get lastUpdate;// ------------------------------------------------------------------
// Fields ported from the legacy search/ ChargingStation (#560).
// Kept optional / defaulted so existing EV callers don't have to
// pass them.
// ------------------------------------------------------------------
 double get dist; String? get postCode; String? get place; int get totalPoints; bool? get isOperational; String? get usageCost; String? get updatedAt; String? get countryCode;
/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingStationCopyWith<ChargingStation> get copyWith => _$ChargingStationCopyWithImpl<ChargingStation>(this as ChargingStation, _$identity);

  /// Serializes this ChargingStation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingStation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.address, address) || other.address == address)&&const DeepCollectionEquality().equals(other.connectors, connectors)&&const DeepCollectionEquality().equals(other.amenities, amenities)&&(identical(other.openingHours, openingHours) || other.openingHours == openingHours)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate)&&(identical(other.dist, dist) || other.dist == dist)&&(identical(other.postCode, postCode) || other.postCode == postCode)&&(identical(other.place, place) || other.place == place)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.isOperational, isOperational) || other.isOperational == isOperational)&&(identical(other.usageCost, usageCost) || other.usageCost == usageCost)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,operator,latitude,longitude,address,const DeepCollectionEquality().hash(connectors),const DeepCollectionEquality().hash(amenities),openingHours,lastUpdate,dist,postCode,place,totalPoints,isOperational,usageCost,updatedAt,countryCode);

@override
String toString() {
  return 'ChargingStation(id: $id, name: $name, operator: $operator, latitude: $latitude, longitude: $longitude, address: $address, connectors: $connectors, amenities: $amenities, openingHours: $openingHours, lastUpdate: $lastUpdate, dist: $dist, postCode: $postCode, place: $place, totalPoints: $totalPoints, isOperational: $isOperational, usageCost: $usageCost, updatedAt: $updatedAt, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class $ChargingStationCopyWith<$Res>  {
  factory $ChargingStationCopyWith(ChargingStation value, $Res Function(ChargingStation) _then) = _$ChargingStationCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? operator, double latitude, double longitude, String? address,@EvConnectorListConverter() List<EvConnector> connectors, List<String> amenities,@OpeningHoursNullableConverter() OpeningHours? openingHours, DateTime? lastUpdate, double dist, String? postCode, String? place, int totalPoints, bool? isOperational, String? usageCost, String? updatedAt, String? countryCode
});


$OpeningHoursCopyWith<$Res>? get openingHours;

}
/// @nodoc
class _$ChargingStationCopyWithImpl<$Res>
    implements $ChargingStationCopyWith<$Res> {
  _$ChargingStationCopyWithImpl(this._self, this._then);

  final ChargingStation _self;
  final $Res Function(ChargingStation) _then;

/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? operator = freezed,Object? latitude = null,Object? longitude = null,Object? address = freezed,Object? connectors = null,Object? amenities = null,Object? openingHours = freezed,Object? lastUpdate = freezed,Object? dist = null,Object? postCode = freezed,Object? place = freezed,Object? totalPoints = null,Object? isOperational = freezed,Object? usageCost = freezed,Object? updatedAt = freezed,Object? countryCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,operator: freezed == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,connectors: null == connectors ? _self.connectors : connectors // ignore: cast_nullable_to_non_nullable
as List<EvConnector>,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,openingHours: freezed == openingHours ? _self.openingHours : openingHours // ignore: cast_nullable_to_non_nullable
as OpeningHours?,lastUpdate: freezed == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime?,dist: null == dist ? _self.dist : dist // ignore: cast_nullable_to_non_nullable
as double,postCode: freezed == postCode ? _self.postCode : postCode // ignore: cast_nullable_to_non_nullable
as String?,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String?,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,isOperational: freezed == isOperational ? _self.isOperational : isOperational // ignore: cast_nullable_to_non_nullable
as bool?,usageCost: freezed == usageCost ? _self.usageCost : usageCost // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpeningHoursCopyWith<$Res>? get openingHours {
    if (_self.openingHours == null) {
    return null;
  }

  return $OpeningHoursCopyWith<$Res>(_self.openingHours!, (value) {
    return _then(_self.copyWith(openingHours: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChargingStation].
extension ChargingStationPatterns on ChargingStation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChargingStation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChargingStation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChargingStation value)  $default,){
final _that = this;
switch (_that) {
case _ChargingStation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChargingStation value)?  $default,){
final _that = this;
switch (_that) {
case _ChargingStation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? operator,  double latitude,  double longitude,  String? address, @EvConnectorListConverter()  List<EvConnector> connectors,  List<String> amenities, @OpeningHoursNullableConverter()  OpeningHours? openingHours,  DateTime? lastUpdate,  double dist,  String? postCode,  String? place,  int totalPoints,  bool? isOperational,  String? usageCost,  String? updatedAt,  String? countryCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingStation() when $default != null:
return $default(_that.id,_that.name,_that.operator,_that.latitude,_that.longitude,_that.address,_that.connectors,_that.amenities,_that.openingHours,_that.lastUpdate,_that.dist,_that.postCode,_that.place,_that.totalPoints,_that.isOperational,_that.usageCost,_that.updatedAt,_that.countryCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? operator,  double latitude,  double longitude,  String? address, @EvConnectorListConverter()  List<EvConnector> connectors,  List<String> amenities, @OpeningHoursNullableConverter()  OpeningHours? openingHours,  DateTime? lastUpdate,  double dist,  String? postCode,  String? place,  int totalPoints,  bool? isOperational,  String? usageCost,  String? updatedAt,  String? countryCode)  $default,) {final _that = this;
switch (_that) {
case _ChargingStation():
return $default(_that.id,_that.name,_that.operator,_that.latitude,_that.longitude,_that.address,_that.connectors,_that.amenities,_that.openingHours,_that.lastUpdate,_that.dist,_that.postCode,_that.place,_that.totalPoints,_that.isOperational,_that.usageCost,_that.updatedAt,_that.countryCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? operator,  double latitude,  double longitude,  String? address, @EvConnectorListConverter()  List<EvConnector> connectors,  List<String> amenities, @OpeningHoursNullableConverter()  OpeningHours? openingHours,  DateTime? lastUpdate,  double dist,  String? postCode,  String? place,  int totalPoints,  bool? isOperational,  String? usageCost,  String? updatedAt,  String? countryCode)?  $default,) {final _that = this;
switch (_that) {
case _ChargingStation() when $default != null:
return $default(_that.id,_that.name,_that.operator,_that.latitude,_that.longitude,_that.address,_that.connectors,_that.amenities,_that.openingHours,_that.lastUpdate,_that.dist,_that.postCode,_that.place,_that.totalPoints,_that.isOperational,_that.usageCost,_that.updatedAt,_that.countryCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingStation extends ChargingStation {
  const _ChargingStation({required this.id, required this.name, this.operator, required this.latitude, required this.longitude, this.address, @EvConnectorListConverter() final  List<EvConnector> connectors = const <EvConnector>[], final  List<String> amenities = const <String>[], @OpeningHoursNullableConverter() this.openingHours, this.lastUpdate, this.dist = 0, this.postCode, this.place, this.totalPoints = 0, this.isOperational, this.usageCost, this.updatedAt, this.countryCode}): _connectors = connectors,_amenities = amenities,super._();
  factory _ChargingStation.fromJson(Map<String, dynamic> json) => _$ChargingStationFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? operator;
@override final  double latitude;
@override final  double longitude;
@override final  String? address;
 final  List<EvConnector> _connectors;
@override@JsonKey()@EvConnectorListConverter() List<EvConnector> get connectors {
  if (_connectors is EqualUnmodifiableListView) return _connectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connectors);
}

 final  List<String> _amenities;
@override@JsonKey() List<String> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

@override@OpeningHoursNullableConverter() final  OpeningHours? openingHours;
@override final  DateTime? lastUpdate;
// ------------------------------------------------------------------
// Fields ported from the legacy search/ ChargingStation (#560).
// Kept optional / defaulted so existing EV callers don't have to
// pass them.
// ------------------------------------------------------------------
@override@JsonKey() final  double dist;
@override final  String? postCode;
@override final  String? place;
@override@JsonKey() final  int totalPoints;
@override final  bool? isOperational;
@override final  String? usageCost;
@override final  String? updatedAt;
@override final  String? countryCode;

/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChargingStationCopyWith<_ChargingStation> get copyWith => __$ChargingStationCopyWithImpl<_ChargingStation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChargingStationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingStation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.address, address) || other.address == address)&&const DeepCollectionEquality().equals(other._connectors, _connectors)&&const DeepCollectionEquality().equals(other._amenities, _amenities)&&(identical(other.openingHours, openingHours) || other.openingHours == openingHours)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate)&&(identical(other.dist, dist) || other.dist == dist)&&(identical(other.postCode, postCode) || other.postCode == postCode)&&(identical(other.place, place) || other.place == place)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.isOperational, isOperational) || other.isOperational == isOperational)&&(identical(other.usageCost, usageCost) || other.usageCost == usageCost)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,operator,latitude,longitude,address,const DeepCollectionEquality().hash(_connectors),const DeepCollectionEquality().hash(_amenities),openingHours,lastUpdate,dist,postCode,place,totalPoints,isOperational,usageCost,updatedAt,countryCode);

@override
String toString() {
  return 'ChargingStation(id: $id, name: $name, operator: $operator, latitude: $latitude, longitude: $longitude, address: $address, connectors: $connectors, amenities: $amenities, openingHours: $openingHours, lastUpdate: $lastUpdate, dist: $dist, postCode: $postCode, place: $place, totalPoints: $totalPoints, isOperational: $isOperational, usageCost: $usageCost, updatedAt: $updatedAt, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class _$ChargingStationCopyWith<$Res> implements $ChargingStationCopyWith<$Res> {
  factory _$ChargingStationCopyWith(_ChargingStation value, $Res Function(_ChargingStation) _then) = __$ChargingStationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? operator, double latitude, double longitude, String? address,@EvConnectorListConverter() List<EvConnector> connectors, List<String> amenities,@OpeningHoursNullableConverter() OpeningHours? openingHours, DateTime? lastUpdate, double dist, String? postCode, String? place, int totalPoints, bool? isOperational, String? usageCost, String? updatedAt, String? countryCode
});


@override $OpeningHoursCopyWith<$Res>? get openingHours;

}
/// @nodoc
class __$ChargingStationCopyWithImpl<$Res>
    implements _$ChargingStationCopyWith<$Res> {
  __$ChargingStationCopyWithImpl(this._self, this._then);

  final _ChargingStation _self;
  final $Res Function(_ChargingStation) _then;

/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? operator = freezed,Object? latitude = null,Object? longitude = null,Object? address = freezed,Object? connectors = null,Object? amenities = null,Object? openingHours = freezed,Object? lastUpdate = freezed,Object? dist = null,Object? postCode = freezed,Object? place = freezed,Object? totalPoints = null,Object? isOperational = freezed,Object? usageCost = freezed,Object? updatedAt = freezed,Object? countryCode = freezed,}) {
  return _then(_ChargingStation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,operator: freezed == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,connectors: null == connectors ? _self._connectors : connectors // ignore: cast_nullable_to_non_nullable
as List<EvConnector>,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<String>,openingHours: freezed == openingHours ? _self.openingHours : openingHours // ignore: cast_nullable_to_non_nullable
as OpeningHours?,lastUpdate: freezed == lastUpdate ? _self.lastUpdate : lastUpdate // ignore: cast_nullable_to_non_nullable
as DateTime?,dist: null == dist ? _self.dist : dist // ignore: cast_nullable_to_non_nullable
as double,postCode: freezed == postCode ? _self.postCode : postCode // ignore: cast_nullable_to_non_nullable
as String?,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String?,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,isOperational: freezed == isOperational ? _self.isOperational : isOperational // ignore: cast_nullable_to_non_nullable
as bool?,usageCost: freezed == usageCost ? _self.usageCost : usageCost // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OpeningHoursCopyWith<$Res>? get openingHours {
    if (_self.openingHours == null) {
    return null;
  }

  return $OpeningHoursCopyWith<$Res>(_self.openingHours!, (value) {
    return _then(_self.copyWith(openingHours: value));
  });
}
}

// dart format on
