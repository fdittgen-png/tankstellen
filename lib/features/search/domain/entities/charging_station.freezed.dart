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
mixin _$ChargingStation {

 String get id; String get name; String get operator; double get lat; double get lng; double get dist; String get address; String get postCode; String get place; List<Connector> get connectors; int get totalPoints; bool? get isOperational; String? get usageCost; String? get updatedAt; String? get countryCode;
/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingStationCopyWith<ChargingStation> get copyWith => _$ChargingStationCopyWithImpl<ChargingStation>(this as ChargingStation, _$identity);

  /// Serializes this ChargingStation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingStation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.dist, dist) || other.dist == dist)&&(identical(other.address, address) || other.address == address)&&(identical(other.postCode, postCode) || other.postCode == postCode)&&(identical(other.place, place) || other.place == place)&&const DeepCollectionEquality().equals(other.connectors, connectors)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.isOperational, isOperational) || other.isOperational == isOperational)&&(identical(other.usageCost, usageCost) || other.usageCost == usageCost)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,operator,lat,lng,dist,address,postCode,place,const DeepCollectionEquality().hash(connectors),totalPoints,isOperational,usageCost,updatedAt,countryCode);

@override
String toString() {
  return 'ChargingStation(id: $id, name: $name, operator: $operator, lat: $lat, lng: $lng, dist: $dist, address: $address, postCode: $postCode, place: $place, connectors: $connectors, totalPoints: $totalPoints, isOperational: $isOperational, usageCost: $usageCost, updatedAt: $updatedAt, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class $ChargingStationCopyWith<$Res>  {
  factory $ChargingStationCopyWith(ChargingStation value, $Res Function(ChargingStation) _then) = _$ChargingStationCopyWithImpl;
@useResult
$Res call({
 String id, String name, String operator, double lat, double lng, double dist, String address, String postCode, String place, List<Connector> connectors, int totalPoints, bool? isOperational, String? usageCost, String? updatedAt, String? countryCode
});




}
/// @nodoc
class _$ChargingStationCopyWithImpl<$Res>
    implements $ChargingStationCopyWith<$Res> {
  _$ChargingStationCopyWithImpl(this._self, this._then);

  final ChargingStation _self;
  final $Res Function(ChargingStation) _then;

/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? operator = null,Object? lat = null,Object? lng = null,Object? dist = null,Object? address = null,Object? postCode = null,Object? place = null,Object? connectors = null,Object? totalPoints = null,Object? isOperational = freezed,Object? usageCost = freezed,Object? updatedAt = freezed,Object? countryCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,dist: null == dist ? _self.dist : dist // ignore: cast_nullable_to_non_nullable
as double,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,postCode: null == postCode ? _self.postCode : postCode // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,connectors: null == connectors ? _self.connectors : connectors // ignore: cast_nullable_to_non_nullable
as List<Connector>,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,isOperational: freezed == isOperational ? _self.isOperational : isOperational // ignore: cast_nullable_to_non_nullable
as bool?,usageCost: freezed == usageCost ? _self.usageCost : usageCost // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String operator,  double lat,  double lng,  double dist,  String address,  String postCode,  String place,  List<Connector> connectors,  int totalPoints,  bool? isOperational,  String? usageCost,  String? updatedAt,  String? countryCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingStation() when $default != null:
return $default(_that.id,_that.name,_that.operator,_that.lat,_that.lng,_that.dist,_that.address,_that.postCode,_that.place,_that.connectors,_that.totalPoints,_that.isOperational,_that.usageCost,_that.updatedAt,_that.countryCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String operator,  double lat,  double lng,  double dist,  String address,  String postCode,  String place,  List<Connector> connectors,  int totalPoints,  bool? isOperational,  String? usageCost,  String? updatedAt,  String? countryCode)  $default,) {final _that = this;
switch (_that) {
case _ChargingStation():
return $default(_that.id,_that.name,_that.operator,_that.lat,_that.lng,_that.dist,_that.address,_that.postCode,_that.place,_that.connectors,_that.totalPoints,_that.isOperational,_that.usageCost,_that.updatedAt,_that.countryCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String operator,  double lat,  double lng,  double dist,  String address,  String postCode,  String place,  List<Connector> connectors,  int totalPoints,  bool? isOperational,  String? usageCost,  String? updatedAt,  String? countryCode)?  $default,) {final _that = this;
switch (_that) {
case _ChargingStation() when $default != null:
return $default(_that.id,_that.name,_that.operator,_that.lat,_that.lng,_that.dist,_that.address,_that.postCode,_that.place,_that.connectors,_that.totalPoints,_that.isOperational,_that.usageCost,_that.updatedAt,_that.countryCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingStation implements ChargingStation {
  const _ChargingStation({required this.id, required this.name, required this.operator, required this.lat, required this.lng, this.dist = 0, required this.address, this.postCode = '', this.place = '', required final  List<Connector> connectors, this.totalPoints = 0, this.isOperational, this.usageCost, this.updatedAt, this.countryCode}): _connectors = connectors;
  factory _ChargingStation.fromJson(Map<String, dynamic> json) => _$ChargingStationFromJson(json);

@override final  String id;
@override final  String name;
@override final  String operator;
@override final  double lat;
@override final  double lng;
@override@JsonKey() final  double dist;
@override final  String address;
@override@JsonKey() final  String postCode;
@override@JsonKey() final  String place;
 final  List<Connector> _connectors;
@override List<Connector> get connectors {
  if (_connectors is EqualUnmodifiableListView) return _connectors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_connectors);
}

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingStation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.dist, dist) || other.dist == dist)&&(identical(other.address, address) || other.address == address)&&(identical(other.postCode, postCode) || other.postCode == postCode)&&(identical(other.place, place) || other.place == place)&&const DeepCollectionEquality().equals(other._connectors, _connectors)&&(identical(other.totalPoints, totalPoints) || other.totalPoints == totalPoints)&&(identical(other.isOperational, isOperational) || other.isOperational == isOperational)&&(identical(other.usageCost, usageCost) || other.usageCost == usageCost)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,operator,lat,lng,dist,address,postCode,place,const DeepCollectionEquality().hash(_connectors),totalPoints,isOperational,usageCost,updatedAt,countryCode);

@override
String toString() {
  return 'ChargingStation(id: $id, name: $name, operator: $operator, lat: $lat, lng: $lng, dist: $dist, address: $address, postCode: $postCode, place: $place, connectors: $connectors, totalPoints: $totalPoints, isOperational: $isOperational, usageCost: $usageCost, updatedAt: $updatedAt, countryCode: $countryCode)';
}


}

/// @nodoc
abstract mixin class _$ChargingStationCopyWith<$Res> implements $ChargingStationCopyWith<$Res> {
  factory _$ChargingStationCopyWith(_ChargingStation value, $Res Function(_ChargingStation) _then) = __$ChargingStationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String operator, double lat, double lng, double dist, String address, String postCode, String place, List<Connector> connectors, int totalPoints, bool? isOperational, String? usageCost, String? updatedAt, String? countryCode
});




}
/// @nodoc
class __$ChargingStationCopyWithImpl<$Res>
    implements _$ChargingStationCopyWith<$Res> {
  __$ChargingStationCopyWithImpl(this._self, this._then);

  final _ChargingStation _self;
  final $Res Function(_ChargingStation) _then;

/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? operator = null,Object? lat = null,Object? lng = null,Object? dist = null,Object? address = null,Object? postCode = null,Object? place = null,Object? connectors = null,Object? totalPoints = null,Object? isOperational = freezed,Object? usageCost = freezed,Object? updatedAt = freezed,Object? countryCode = freezed,}) {
  return _then(_ChargingStation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,dist: null == dist ? _self.dist : dist // ignore: cast_nullable_to_non_nullable
as double,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,postCode: null == postCode ? _self.postCode : postCode // ignore: cast_nullable_to_non_nullable
as String,place: null == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as String,connectors: null == connectors ? _self._connectors : connectors // ignore: cast_nullable_to_non_nullable
as List<Connector>,totalPoints: null == totalPoints ? _self.totalPoints : totalPoints // ignore: cast_nullable_to_non_nullable
as int,isOperational: freezed == isOperational ? _self.isOperational : isOperational // ignore: cast_nullable_to_non_nullable
as bool?,usageCost: freezed == usageCost ? _self.usageCost : usageCost // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Connector {

 String get type;// "CCS", "Type 2", "CHAdeMO", "Tesla"
 double get powerKW; int get quantity; String? get currentType;// "AC", "DC"
 String? get status;
/// Create a copy of Connector
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectorCopyWith<Connector> get copyWith => _$ConnectorCopyWithImpl<Connector>(this as Connector, _$identity);

  /// Serializes this Connector to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Connector&&(identical(other.type, type) || other.type == type)&&(identical(other.powerKW, powerKW) || other.powerKW == powerKW)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.currentType, currentType) || other.currentType == currentType)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,powerKW,quantity,currentType,status);

@override
String toString() {
  return 'Connector(type: $type, powerKW: $powerKW, quantity: $quantity, currentType: $currentType, status: $status)';
}


}

/// @nodoc
abstract mixin class $ConnectorCopyWith<$Res>  {
  factory $ConnectorCopyWith(Connector value, $Res Function(Connector) _then) = _$ConnectorCopyWithImpl;
@useResult
$Res call({
 String type, double powerKW, int quantity, String? currentType, String? status
});




}
/// @nodoc
class _$ConnectorCopyWithImpl<$Res>
    implements $ConnectorCopyWith<$Res> {
  _$ConnectorCopyWithImpl(this._self, this._then);

  final Connector _self;
  final $Res Function(Connector) _then;

/// Create a copy of Connector
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? powerKW = null,Object? quantity = null,Object? currentType = freezed,Object? status = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,powerKW: null == powerKW ? _self.powerKW : powerKW // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,currentType: freezed == currentType ? _self.currentType : currentType // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Connector].
extension ConnectorPatterns on Connector {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Connector value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Connector() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Connector value)  $default,){
final _that = this;
switch (_that) {
case _Connector():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Connector value)?  $default,){
final _that = this;
switch (_that) {
case _Connector() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  double powerKW,  int quantity,  String? currentType,  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Connector() when $default != null:
return $default(_that.type,_that.powerKW,_that.quantity,_that.currentType,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  double powerKW,  int quantity,  String? currentType,  String? status)  $default,) {final _that = this;
switch (_that) {
case _Connector():
return $default(_that.type,_that.powerKW,_that.quantity,_that.currentType,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  double powerKW,  int quantity,  String? currentType,  String? status)?  $default,) {final _that = this;
switch (_that) {
case _Connector() when $default != null:
return $default(_that.type,_that.powerKW,_that.quantity,_that.currentType,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Connector implements Connector {
  const _Connector({required this.type, this.powerKW = 0, this.quantity = 0, this.currentType, this.status});
  factory _Connector.fromJson(Map<String, dynamic> json) => _$ConnectorFromJson(json);

@override final  String type;
// "CCS", "Type 2", "CHAdeMO", "Tesla"
@override@JsonKey() final  double powerKW;
@override@JsonKey() final  int quantity;
@override final  String? currentType;
// "AC", "DC"
@override final  String? status;

/// Create a copy of Connector
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectorCopyWith<_Connector> get copyWith => __$ConnectorCopyWithImpl<_Connector>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConnectorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Connector&&(identical(other.type, type) || other.type == type)&&(identical(other.powerKW, powerKW) || other.powerKW == powerKW)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.currentType, currentType) || other.currentType == currentType)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,powerKW,quantity,currentType,status);

@override
String toString() {
  return 'Connector(type: $type, powerKW: $powerKW, quantity: $quantity, currentType: $currentType, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ConnectorCopyWith<$Res> implements $ConnectorCopyWith<$Res> {
  factory _$ConnectorCopyWith(_Connector value, $Res Function(_Connector) _then) = __$ConnectorCopyWithImpl;
@override @useResult
$Res call({
 String type, double powerKW, int quantity, String? currentType, String? status
});




}
/// @nodoc
class __$ConnectorCopyWithImpl<$Res>
    implements _$ConnectorCopyWith<$Res> {
  __$ConnectorCopyWithImpl(this._self, this._then);

  final _Connector _self;
  final $Res Function(_Connector) _then;

/// Create a copy of Connector
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? powerKW = null,Object? quantity = null,Object? currentType = freezed,Object? status = freezed,}) {
  return _then(_Connector(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,powerKW: null == powerKW ? _self.powerKW : powerKW // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,currentType: freezed == currentType ? _self.currentType : currentType // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
