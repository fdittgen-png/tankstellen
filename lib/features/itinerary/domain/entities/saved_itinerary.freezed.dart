// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_itinerary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedItinerary {

 String get id; String get name; List<Map<String, dynamic>> get waypoints; double get distanceKm; double get durationMinutes; bool get avoidHighways; String get fuelType; List<String> get selectedStationIds; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of SavedItinerary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedItineraryCopyWith<SavedItinerary> get copyWith => _$SavedItineraryCopyWithImpl<SavedItinerary>(this as SavedItinerary, _$identity);

  /// Serializes this SavedItinerary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedItinerary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.waypoints, waypoints)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.avoidHighways, avoidHighways) || other.avoidHighways == avoidHighways)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&const DeepCollectionEquality().equals(other.selectedStationIds, selectedStationIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(waypoints),distanceKm,durationMinutes,avoidHighways,fuelType,const DeepCollectionEquality().hash(selectedStationIds),createdAt,updatedAt);

@override
String toString() {
  return 'SavedItinerary(id: $id, name: $name, waypoints: $waypoints, distanceKm: $distanceKm, durationMinutes: $durationMinutes, avoidHighways: $avoidHighways, fuelType: $fuelType, selectedStationIds: $selectedStationIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SavedItineraryCopyWith<$Res>  {
  factory $SavedItineraryCopyWith(SavedItinerary value, $Res Function(SavedItinerary) _then) = _$SavedItineraryCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<Map<String, dynamic>> waypoints, double distanceKm, double durationMinutes, bool avoidHighways, String fuelType, List<String> selectedStationIds, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$SavedItineraryCopyWithImpl<$Res>
    implements $SavedItineraryCopyWith<$Res> {
  _$SavedItineraryCopyWithImpl(this._self, this._then);

  final SavedItinerary _self;
  final $Res Function(SavedItinerary) _then;

/// Create a copy of SavedItinerary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? waypoints = null,Object? distanceKm = null,Object? durationMinutes = null,Object? avoidHighways = null,Object? fuelType = null,Object? selectedStationIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,waypoints: null == waypoints ? _self.waypoints : waypoints // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as double,avoidHighways: null == avoidHighways ? _self.avoidHighways : avoidHighways // ignore: cast_nullable_to_non_nullable
as bool,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String,selectedStationIds: null == selectedStationIds ? _self.selectedStationIds : selectedStationIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedItinerary].
extension SavedItineraryPatterns on SavedItinerary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedItinerary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedItinerary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedItinerary value)  $default,){
final _that = this;
switch (_that) {
case _SavedItinerary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedItinerary value)?  $default,){
final _that = this;
switch (_that) {
case _SavedItinerary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<Map<String, dynamic>> waypoints,  double distanceKm,  double durationMinutes,  bool avoidHighways,  String fuelType,  List<String> selectedStationIds,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedItinerary() when $default != null:
return $default(_that.id,_that.name,_that.waypoints,_that.distanceKm,_that.durationMinutes,_that.avoidHighways,_that.fuelType,_that.selectedStationIds,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<Map<String, dynamic>> waypoints,  double distanceKm,  double durationMinutes,  bool avoidHighways,  String fuelType,  List<String> selectedStationIds,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SavedItinerary():
return $default(_that.id,_that.name,_that.waypoints,_that.distanceKm,_that.durationMinutes,_that.avoidHighways,_that.fuelType,_that.selectedStationIds,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<Map<String, dynamic>> waypoints,  double distanceKm,  double durationMinutes,  bool avoidHighways,  String fuelType,  List<String> selectedStationIds,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SavedItinerary() when $default != null:
return $default(_that.id,_that.name,_that.waypoints,_that.distanceKm,_that.durationMinutes,_that.avoidHighways,_that.fuelType,_that.selectedStationIds,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedItinerary implements SavedItinerary {
  const _SavedItinerary({required this.id, required this.name, required final  List<Map<String, dynamic>> waypoints, required this.distanceKm, required this.durationMinutes, this.avoidHighways = false, this.fuelType = 'e10', final  List<String> selectedStationIds = const [], required this.createdAt, required this.updatedAt}): _waypoints = waypoints,_selectedStationIds = selectedStationIds;
  factory _SavedItinerary.fromJson(Map<String, dynamic> json) => _$SavedItineraryFromJson(json);

@override final  String id;
@override final  String name;
 final  List<Map<String, dynamic>> _waypoints;
@override List<Map<String, dynamic>> get waypoints {
  if (_waypoints is EqualUnmodifiableListView) return _waypoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_waypoints);
}

@override final  double distanceKm;
@override final  double durationMinutes;
@override@JsonKey() final  bool avoidHighways;
@override@JsonKey() final  String fuelType;
 final  List<String> _selectedStationIds;
@override@JsonKey() List<String> get selectedStationIds {
  if (_selectedStationIds is EqualUnmodifiableListView) return _selectedStationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedStationIds);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of SavedItinerary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedItineraryCopyWith<_SavedItinerary> get copyWith => __$SavedItineraryCopyWithImpl<_SavedItinerary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedItineraryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedItinerary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._waypoints, _waypoints)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.avoidHighways, avoidHighways) || other.avoidHighways == avoidHighways)&&(identical(other.fuelType, fuelType) || other.fuelType == fuelType)&&const DeepCollectionEquality().equals(other._selectedStationIds, _selectedStationIds)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_waypoints),distanceKm,durationMinutes,avoidHighways,fuelType,const DeepCollectionEquality().hash(_selectedStationIds),createdAt,updatedAt);

@override
String toString() {
  return 'SavedItinerary(id: $id, name: $name, waypoints: $waypoints, distanceKm: $distanceKm, durationMinutes: $durationMinutes, avoidHighways: $avoidHighways, fuelType: $fuelType, selectedStationIds: $selectedStationIds, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SavedItineraryCopyWith<$Res> implements $SavedItineraryCopyWith<$Res> {
  factory _$SavedItineraryCopyWith(_SavedItinerary value, $Res Function(_SavedItinerary) _then) = __$SavedItineraryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<Map<String, dynamic>> waypoints, double distanceKm, double durationMinutes, bool avoidHighways, String fuelType, List<String> selectedStationIds, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$SavedItineraryCopyWithImpl<$Res>
    implements _$SavedItineraryCopyWith<$Res> {
  __$SavedItineraryCopyWithImpl(this._self, this._then);

  final _SavedItinerary _self;
  final $Res Function(_SavedItinerary) _then;

/// Create a copy of SavedItinerary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? waypoints = null,Object? distanceKm = null,Object? durationMinutes = null,Object? avoidHighways = null,Object? fuelType = null,Object? selectedStationIds = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_SavedItinerary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,waypoints: null == waypoints ? _self._waypoints : waypoints // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as double,avoidHighways: null == avoidHighways ? _self.avoidHighways : avoidHighways // ignore: cast_nullable_to_non_nullable
as bool,fuelType: null == fuelType ? _self.fuelType : fuelType // ignore: cast_nullable_to_non_nullable
as String,selectedStationIds: null == selectedStationIds ? _self._selectedStationIds : selectedStationIds // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
