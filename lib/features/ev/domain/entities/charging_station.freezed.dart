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

 String get id;@ConnectorTypeJsonConverter() ConnectorType get type; double get maxPowerKw;@ConnectorStatusJsonConverter() ConnectorStatus get status; String? get tariffId;
/// Create a copy of EvConnector
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvConnectorCopyWith<EvConnector> get copyWith => _$EvConnectorCopyWithImpl<EvConnector>(this as EvConnector, _$identity);

  /// Serializes this EvConnector to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvConnector&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.maxPowerKw, maxPowerKw) || other.maxPowerKw == maxPowerKw)&&(identical(other.status, status) || other.status == status)&&(identical(other.tariffId, tariffId) || other.tariffId == tariffId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,maxPowerKw,status,tariffId);

@override
String toString() {
  return 'EvConnector(id: $id, type: $type, maxPowerKw: $maxPowerKw, status: $status, tariffId: $tariffId)';
}


}

/// @nodoc
abstract mixin class $EvConnectorCopyWith<$Res>  {
  factory $EvConnectorCopyWith(EvConnector value, $Res Function(EvConnector) _then) = _$EvConnectorCopyWithImpl;
@useResult
$Res call({
 String id,@ConnectorTypeJsonConverter() ConnectorType type, double maxPowerKw,@ConnectorStatusJsonConverter() ConnectorStatus status, String? tariffId
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? maxPowerKw = null,Object? status = null,Object? tariffId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ConnectorType,maxPowerKw: null == maxPowerKw ? _self.maxPowerKw : maxPowerKw // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectorStatus,tariffId: freezed == tariffId ? _self.tariffId : tariffId // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @ConnectorTypeJsonConverter()  ConnectorType type,  double maxPowerKw, @ConnectorStatusJsonConverter()  ConnectorStatus status,  String? tariffId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EvConnector() when $default != null:
return $default(_that.id,_that.type,_that.maxPowerKw,_that.status,_that.tariffId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @ConnectorTypeJsonConverter()  ConnectorType type,  double maxPowerKw, @ConnectorStatusJsonConverter()  ConnectorStatus status,  String? tariffId)  $default,) {final _that = this;
switch (_that) {
case _EvConnector():
return $default(_that.id,_that.type,_that.maxPowerKw,_that.status,_that.tariffId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @ConnectorTypeJsonConverter()  ConnectorType type,  double maxPowerKw, @ConnectorStatusJsonConverter()  ConnectorStatus status,  String? tariffId)?  $default,) {final _that = this;
switch (_that) {
case _EvConnector() when $default != null:
return $default(_that.id,_that.type,_that.maxPowerKw,_that.status,_that.tariffId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EvConnector implements EvConnector {
  const _EvConnector({required this.id, @ConnectorTypeJsonConverter() required this.type, this.maxPowerKw = 0, @ConnectorStatusJsonConverter() this.status = ConnectorStatus.unknown, this.tariffId});
  factory _EvConnector.fromJson(Map<String, dynamic> json) => _$EvConnectorFromJson(json);

@override final  String id;
@override@ConnectorTypeJsonConverter() final  ConnectorType type;
@override@JsonKey() final  double maxPowerKw;
@override@JsonKey()@ConnectorStatusJsonConverter() final  ConnectorStatus status;
@override final  String? tariffId;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EvConnector&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.maxPowerKw, maxPowerKw) || other.maxPowerKw == maxPowerKw)&&(identical(other.status, status) || other.status == status)&&(identical(other.tariffId, tariffId) || other.tariffId == tariffId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,maxPowerKw,status,tariffId);

@override
String toString() {
  return 'EvConnector(id: $id, type: $type, maxPowerKw: $maxPowerKw, status: $status, tariffId: $tariffId)';
}


}

/// @nodoc
abstract mixin class _$EvConnectorCopyWith<$Res> implements $EvConnectorCopyWith<$Res> {
  factory _$EvConnectorCopyWith(_EvConnector value, $Res Function(_EvConnector) _then) = __$EvConnectorCopyWithImpl;
@override @useResult
$Res call({
 String id,@ConnectorTypeJsonConverter() ConnectorType type, double maxPowerKw,@ConnectorStatusJsonConverter() ConnectorStatus status, String? tariffId
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? maxPowerKw = null,Object? status = null,Object? tariffId = freezed,}) {
  return _then(_EvConnector(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ConnectorType,maxPowerKw: null == maxPowerKw ? _self.maxPowerKw : maxPowerKw // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectorStatus,tariffId: freezed == tariffId ? _self.tariffId : tariffId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChargingStation {

 String get id; String get name; String? get operator; double get latitude; double get longitude; String? get address;@EvConnectorListConverter() List<EvConnector> get connectors; List<String> get amenities;@OpeningHoursNullableConverter() OpeningHours? get openingHours; DateTime? get lastUpdate;
/// Create a copy of ChargingStation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChargingStationCopyWith<ChargingStation> get copyWith => _$ChargingStationCopyWithImpl<ChargingStation>(this as ChargingStation, _$identity);

  /// Serializes this ChargingStation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChargingStation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.address, address) || other.address == address)&&const DeepCollectionEquality().equals(other.connectors, connectors)&&const DeepCollectionEquality().equals(other.amenities, amenities)&&(identical(other.openingHours, openingHours) || other.openingHours == openingHours)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,operator,latitude,longitude,address,const DeepCollectionEquality().hash(connectors),const DeepCollectionEquality().hash(amenities),openingHours,lastUpdate);

@override
String toString() {
  return 'ChargingStation(id: $id, name: $name, operator: $operator, latitude: $latitude, longitude: $longitude, address: $address, connectors: $connectors, amenities: $amenities, openingHours: $openingHours, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class $ChargingStationCopyWith<$Res>  {
  factory $ChargingStationCopyWith(ChargingStation value, $Res Function(ChargingStation) _then) = _$ChargingStationCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? operator, double latitude, double longitude, String? address,@EvConnectorListConverter() List<EvConnector> connectors, List<String> amenities,@OpeningHoursNullableConverter() OpeningHours? openingHours, DateTime? lastUpdate
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? operator = freezed,Object? latitude = null,Object? longitude = null,Object? address = freezed,Object? connectors = null,Object? amenities = null,Object? openingHours = freezed,Object? lastUpdate = freezed,}) {
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
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? operator,  double latitude,  double longitude,  String? address, @EvConnectorListConverter()  List<EvConnector> connectors,  List<String> amenities, @OpeningHoursNullableConverter()  OpeningHours? openingHours,  DateTime? lastUpdate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChargingStation() when $default != null:
return $default(_that.id,_that.name,_that.operator,_that.latitude,_that.longitude,_that.address,_that.connectors,_that.amenities,_that.openingHours,_that.lastUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? operator,  double latitude,  double longitude,  String? address, @EvConnectorListConverter()  List<EvConnector> connectors,  List<String> amenities, @OpeningHoursNullableConverter()  OpeningHours? openingHours,  DateTime? lastUpdate)  $default,) {final _that = this;
switch (_that) {
case _ChargingStation():
return $default(_that.id,_that.name,_that.operator,_that.latitude,_that.longitude,_that.address,_that.connectors,_that.amenities,_that.openingHours,_that.lastUpdate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? operator,  double latitude,  double longitude,  String? address, @EvConnectorListConverter()  List<EvConnector> connectors,  List<String> amenities, @OpeningHoursNullableConverter()  OpeningHours? openingHours,  DateTime? lastUpdate)?  $default,) {final _that = this;
switch (_that) {
case _ChargingStation() when $default != null:
return $default(_that.id,_that.name,_that.operator,_that.latitude,_that.longitude,_that.address,_that.connectors,_that.amenities,_that.openingHours,_that.lastUpdate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChargingStation extends ChargingStation {
  const _ChargingStation({required this.id, required this.name, this.operator, required this.latitude, required this.longitude, this.address, @EvConnectorListConverter() final  List<EvConnector> connectors = const <EvConnector>[], final  List<String> amenities = const <String>[], @OpeningHoursNullableConverter() this.openingHours, this.lastUpdate}): _connectors = connectors,_amenities = amenities,super._();
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChargingStation&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.address, address) || other.address == address)&&const DeepCollectionEquality().equals(other._connectors, _connectors)&&const DeepCollectionEquality().equals(other._amenities, _amenities)&&(identical(other.openingHours, openingHours) || other.openingHours == openingHours)&&(identical(other.lastUpdate, lastUpdate) || other.lastUpdate == lastUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,operator,latitude,longitude,address,const DeepCollectionEquality().hash(_connectors),const DeepCollectionEquality().hash(_amenities),openingHours,lastUpdate);

@override
String toString() {
  return 'ChargingStation(id: $id, name: $name, operator: $operator, latitude: $latitude, longitude: $longitude, address: $address, connectors: $connectors, amenities: $amenities, openingHours: $openingHours, lastUpdate: $lastUpdate)';
}


}

/// @nodoc
abstract mixin class _$ChargingStationCopyWith<$Res> implements $ChargingStationCopyWith<$Res> {
  factory _$ChargingStationCopyWith(_ChargingStation value, $Res Function(_ChargingStation) _then) = __$ChargingStationCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? operator, double latitude, double longitude, String? address,@EvConnectorListConverter() List<EvConnector> connectors, List<String> amenities,@OpeningHoursNullableConverter() OpeningHours? openingHours, DateTime? lastUpdate
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? operator = freezed,Object? latitude = null,Object? longitude = null,Object? address = freezed,Object? connectors = null,Object? amenities = null,Object? openingHours = freezed,Object? lastUpdate = freezed,}) {
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
as DateTime?,
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
